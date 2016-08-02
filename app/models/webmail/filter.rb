class Webmail::Filter < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  NUMBER_OF_SLICE_UIDS = 256

  attr_accessor :target_mailbox, :include_sub
  attr_accessor :matched_uids
  attr_reader :applied, :processed, :delayed

  has_many :conditions, -> { order(:sort_no) },
    foreign_key: :filter_id, class_name: 'Webmail::FilterCondition', dependent: :destroy

  accepts_nested_attributes_for :conditions, allow_destroy: true

  before_validation :set_conditions_for_save

  validates :user_id, :state, :name, :conditions_chain, :action, presence: true
  validates :sort_no, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :validate_conditions
  validate :validate_mailbox
  validate :validate_name

  with_options on: :apply do
    validates :target_mailbox, presence: true
    validates :conditions, presence: true
  end

  scope :readable, ->(user = Core.user) { where(user_id: user.id) }

  enumerize :state, in: [:enabled, :disabled]
  enumerize :action, in: [:move, :delete]
  enumerize :conditions_chain, in: [:and, :or]

  def editable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def deletable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def mailbox_name
    Webmail::Mailbox.name_to_title(mailbox).gsub('.', '/')
  end

  def target_mailboxes
    mailboxes = [target_mailbox]
    mailboxes += Core.imap.list('', "#{mailbox}.*").to_a.map(&:name) if include_sub == '1'
    mailboxes
  end

  def schedule_mail_uids
    mail_uids = target_mailboxes.each_with_object({}) do |mailbox, hash|
      uids = Webmail::Mail.find_uids(select: mailbox, conditions: ['UNDELETED'])
      hash[mailbox] = uids.sort.reverse
    end
    self.class.schedule_mail_uids(mail_uids)
  end

  def apply
    @applied = 0
    @processed = 0
    @delayed = 0

    process_uids, delay_uids = schedule_mail_uids
    process_uids.each do |mailbox, uids|
      applied_uids = apply_to(mailbox: mailbox, uids: uids)
      @processed += uids.size
      @applied += applied_uids.size
    end
    delay_uids.each do |mailbox, uids|
      Webmail::FilterJob.new(user: Core.current_user, mailbox: mailbox, uids: uids).delay(queue: 'filter').perform
      @delayed += uids.size
    end
  end

  def apply_to(mailbox:, uids:)
    applied_uids = self.class.apply_uids([self], mailbox: mailbox, uids: uids)

    if applied_uids.size > 0
      starred_uids = Webmail::MailNode.find_ref_nodes(mailbox, applied_uids).map{|x| x.uid}
      if starred_uids.present?
        Core.imap.select('Star')
        num = Core.imap.uid_store(starred_uids, '+FLAGS', [:Deleted]).to_a.size
        Core.imap.expunge
        if num > 0
          Webmail::MailNode.delete_nodes('Star', starred_uids)
        end
      end
    end
    applied_uids
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
      Webmail::Mail.move_all(target_mailbox, mailbox, uids)
    when 'delete'
      Webmail::Mail.delete_all(target_mailbox, uids)
    else
      uids = []
    end
    Webmail::MailNode.delete_nodes(target_mailbox, uids) if options[:delete_cache]
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
      st = Webmail::Setting.where(user_id: Core.current_user.id, name: 'last_uid').first_or_initialize(value: 1)
      next_uid = Core.imap.status('INBOX', ['UIDNEXT'])['UIDNEXT']
      last_uid = (next_uid > 1) ? next_uid - 1 : 1
      imap_cnd = st.value.blank? ? ['RECENT'] : ['UID', "#{st.value.to_i}:#{last_uid}", 'UNSEEN']

      delayed = 0
      filters = self.where(user_id: Core.current_user.id, state: 'enabled')
        .order(:sort_no, :id)
        .preload(:conditions)

      if filters.size > 0
        uids = Webmail::Mail.find_uids(select: 'INBOX', conditions: imap_cnd)
        if uids.present?
          process_uids, delay_uids = schedule_mail_uids('INBOX' => uids)
          if process_uids.present?
            process_uids.each do |mailbox, uids|
              apply_uids(filters, mailbox: mailbox, uids: uids)
            end
          end
          if delay_uids.present?
            delay_uids.each do |mailbox, uids|
              Webmail::FilterJob.new(user: Core.current_user, mailbox: mailbox, uids: uids)
                .delay(queue: 'filter').perform
              delayed += uids.size
            end
          end
        end
      end

      if last_uid != st.value.to_i
        st.value = last_uid
        st.save(validate: false)
        recent = true
      else
        recent = false
      end
      return last_uid, recent, delayed
    end

    def schedule_mail_uids(mail_uids)
      count = 0
      process_uids = {}
      delay_uids = {}
      max_count = Joruri.config.application['webmail.filter_max_mail_count_at_once']

      mail_uids.each do |mailbox, uids|
        uids.each do |uid|
          if count >= max_count
            delay_uids[mailbox] ||= []
            delay_uids[mailbox] << uid
          else 
            process_uids[mailbox] ||= []
            process_uids[mailbox] << uid
          end
          count += 1
        end
      end
      return process_uids, delay_uids
    end

    def apply_uids(filters, mailbox:, uids:, delete_cache: true)
      applied_uids = []
      uids.each_slice(NUMBER_OF_SLICE_UIDS) do |sliced_uids|
        applied_uids += apply_uids_for_each_slice(filters, mailbox: mailbox, uids: sliced_uids, delete_cache: delete_cache)
      end
      applied_uids
    end

    def apply_uids_for_each_slice(filters, mailbox:, uids:, delete_cache: true)
      mails = Webmail::Mail.fetch_for_filter(uids, mailbox)
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
          applied_uids += filter.perform_action(mailbox, filter.matched_uids, delete_cache: delete_cache)
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
