class Gw::WebmailFilter < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  NUMBER_OF_SLICE_UIDS = 256

  belongs_to_active_hash :status, foreign_key: :state, class_name: 'Sys::Base::Status'

  has_many :conditions, -> { order(:sort_no) },
    foreign_key: :filter_id, class_name: 'Gw::WebmailFilterCondition', dependent: :destroy

  accepts_nested_attributes_for :conditions, allow_destroy: true

  attr_accessor :include_sub
  attr_accessor :matched_uids
  attr_reader :applied

  validates :user_id, :state, :name, :conditions_chain, :action, presence: true
  validates :sort_no, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :validate_conditions
  validate :validate_mailbox
  validate :validate_name

  before_validation :set_conditions_for_save

  scope :readable, ->(user = Core.user) { where(user_id: user.id) }

  def editable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def deletable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def states
    [['有効','enabled'],['無効','disabled']]
  end

  def action_labels
    [["メールを移動する", "move"],["メールを削除する","delete"]]
  end

  def state_label
    states.each {|a| return a[0] if state == a[1].to_s }
    nil
  end

  def action_label
    action_labels.each {|a| return a[0] if action == a[1].to_s }
    nil
  end

  def mailbox_name
    Gw::WebmailMailbox.name_to_title(mailbox).gsub('.', '/')
  end

  def conditions_chain_labels
    [["全ての条件に一致", "and"],["いずれかの条件に一致","or"]]
  end

  def conditions_chain_label
    conditions_chain_labels.each {|a| return a[0] if conditions_chain == a[1].to_s }
    nil
  end

  def apply(select:, conditions:, timeout:)
    @applied = 0
    applied_uids = []

    uids = Gw::WebmailMail.find_uids(select: select, conditions: conditions)
    uids.each_slice(NUMBER_OF_SLICE_UIDS) do |slice_uids|
      timeout.check 
      applied_uids += self.class.apply_uids([self], select, slice_uids, delete_cache: true)
      @applied = applied_uids.size
    end
  ensure
    if applied_uids.size > 0
      starred_uids = Gw::WebmailMailNode.find_ref_nodes(select, applied_uids).map{|x| x.uid}
      if starred_uids.present?
        Core.imap.select('Star')
        num = Core.imap.uid_store(starred_uids, '+FLAGS', [:Deleted]).to_a.size
        Core.imap.expunge
        if num > 0
          Gw::WebmailMailNode.delete_nodes('Star', starred_uids)
        end
      end
    end
  end

  def delete_exceeded_conditions
    max_count = Joruri.config.application['webmail.filter_condition_max_count'] 
    curr_count = conditions.size
    if curr_count > max_count
      ids = conditions.limit(curr_count - max_count).pluck(:id)
      conditions.where(id: ids).delete_all
    end
  end

  def match?(mail_data = {})
    case conditions_chain
    when 'or'
      conditions.any? { |c| c.match?(mail_data) }
    when 'and'
      conditions.all? { |c| c.match?(mail_data) }
    else
      false
    end
  end

  def perform_action(target_mailbox, uids, options = {})
    case action
    when 'move'
      Gw::WebmailMail.move_all(target_mailbox, mailbox, uids)
    when 'delete'
      Gw::WebmailMail.delete_all(target_mailbox, uids)
    else
      uids = []
    end
    Gw::WebmailMailNode.delete_nodes(target_mailbox, uids) if options[:delete_cache]
    uids
  rescue => e
    error_log(e)
    []
  end

  private

  def validate_mailbox
    return true if mailbox.present?
    return true if action !~ /^(move)$/
    errors.add :mailbox, :empty
  end

  def validate_name
    if name_changed?
      if (name_was == nil || name_was =~ /^[^*]/) && name =~ /^[*]/
        errors.add :name, "の先頭文字は*以外を入力してください。"
        name.gsub!(/^[*]+/, '')
      end
    end
  end

  def validate_conditions
    if conditions.reject(&:marked_for_destruction?).blank?
      return errors.add(:conditions, :empty)
    end
  end

  def set_conditions_for_save
    conditions.each_with_index do |c, i|
      c.user_id = user_id
      c.sort_no = i
      c.mark_for_destruction if c.column.blank? && c.inclusion.blank? && c.value.blank?
    end
  end

  class << self
    def apply_recents
      st = Gw::WebmailSetting.where(user_id: Core.current_user.id, name: 'last_uid').first_or_initialize
      next_uid = Core.imap.status('INBOX', ['UIDNEXT'])['UIDNEXT']
      last_uid = (next_uid > 1) ? next_uid - 1 : 1
      imap_cnd = st.value.blank? ? ['RECENT'] : ['UID', "#{st.value.to_i + 1}:#{last_uid}", 'UNSEEN']

      filters = self.where(user_id: Core.current_user.id, state: 'enabled')
        .order(:sort_no, :id)
        .preload(:conditions)

      if filters.size > 0
        timeout = Sys::Lib::Timeout.new(60)
        uids = Gw::WebmailMail.find_uids(select: 'INBOX', conditions: imap_cnd)
        begin
          uids.each_slice(NUMBER_OF_SLICE_UIDS) do |slice_uids|
            timeout.check
            apply_uids(filters, 'INBOX', slice_uids)
          end
        rescue Sys::Lib::Timeout::Error => e
          error = e
        end        
      end

      if last_uid != st.value.to_i
        st.value = last_uid
        st.save(validate: false)
        recent = true
      else
        recent = false
      end
      return last_uid, recent, error
    end

    def apply_uids(filters, mailbox, uids, options = {})
      filters = Array(filters)
      mails = Gw::WebmailMail.fetch_for_filter(uids, mailbox)
      mails.each do |mail|
        mail_data = {
          subject: [mail.subject],
          from: [mail.friendly_from_addr],
          to: mail.friendly_to_addrs
        }
        filters.each_with_index do |filter, idx|
          if filter.match?(mail_data)
            filter.matched_uids ||= []
            filter.matched_uids << mail.uid
            break
          end
        end
      end

      applied_uids = []
      filters.each do |filter|
        if filter.matched_uids.present?
          applied_uids += filter.perform_action(mailbox, filter.matched_uids, options)
        end
      end
      applied_uids
    end

    def load_spam_filter
      filter = self.where(user_id: Core.current_user.id, name: '* 迷惑メール').first_or_initialize do |f|
        f.state = 'enabled'
        f.sort_no = 0
        f.conditions_chain = 'or'
        f.action = 'delete'
        f.mailbox = ''
      end
      filter.save(validate: false) if filter.new_record?
      filter
    end

    def register_spams(items)
      filter = load_spam_filter

      last_condition = filter.conditions.last
      next_sort_no = last_condition ? last_condition.sort_no + 1 : 0

      items.each_with_index do |item, i|
        next if filter.conditions.detect { |c| c.column == 'from' && c.inclusion == '<' && c.value == item.from_addr }
        filter.conditions.build(
          user_id: Core.current_user.id,
          sort_no: next_sort_no + 1,
          column: 'from', inclusion: '<', value: item.from_addr
        ).save(validate: false)
      end

      filter.delete_exceeded_conditions
    end
  end
end
