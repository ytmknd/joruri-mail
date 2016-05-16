class Gw::WebmailFilter < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  NUMBER_OF_FILTERED_UIDS = 256

  belongs_to_active_hash :status, foreign_key: :state, class_name: 'Sys::Base::Status'

  has_many :conditions, -> { order(:sort_no) },
    foreign_key: :filter_id, class_name: 'Gw::WebmailFilterCondition', dependent: :destroy

  attr_accessor :in_columns, :in_inclusions, :in_values, :include_sub
  attr_reader :applied

  validates :user_id, :state, :name, :conditions_chain, :action, presence: true
  validates :sort_no, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  validate :validate_conditions
  validate :validate_mailbox
  validate :validate_name

  after_save :save_conditions

  scope :readable, ->(user = Core.user) { where(user_id: user.id) }

  def editable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def deletable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def in_columns
    @in_columns = conditions.collect{|c| c.column} if @in_columns.nil?
    @in_columns
  end

  def in_inclusions
    @in_inclusions = conditions.collect{|c| c.inclusion} if @in_inclusions.nil?
    @in_inclusions
  end

  def in_values
    @in_values = conditions.collect{|c| c.value} if @in_values.nil?
    @in_values
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

  def condition_column_labels
    [["件名（Subject）","subject"],["差出人（From）","from"],["宛先（To）","to"]]
  end

  def condition_inclusion_labels
    [["に次を含む","<"],["に次を含まない","!<"],["が次と一致する","=="],["正規表現","=~"]]
  end

  def apply(params)
    @applied = 0
    applied_uids = []
    idx = 0
    params[:filter] = self
    uids = Gw::WebmailMail.find_uid(:all, select: params[:select], conditions: params[:conditions])
    while (filtered = uids[idx, NUMBER_OF_FILTERED_UIDS]) && filtered.size > 0
      params[:timeout].check 
      applied_uids += self.class.apply_uids(filtered, params)
      idx += filtered.size
    end
    @applied = applied_uids.size
    
    starred_uids = Gw::WebmailMailNode.find_ref_nodes(params[:select], applied_uids).map{|x| x.uid}
    Core.imap.select('Star')
    num = Core.imap.uid_store(starred_uids, "+FLAGS", [:Deleted]).size rescue 0
    Core.imap.expunge
    if num > 0
      Gw::WebmailMailNode.delete_nodes('Star', starred_uids)
    end
    
    return @applied
  end

  def self.apply_recents
    filters = Gw::WebmailFilter.where(user_id: Core.current_user.id, state: 'enabled').order(:sort_no, :id)
    st = Gw::WebmailSetting.where(user_id: Core.current_user.id, name: 'last_uid').first_or_initialize

    next_uid = Core.imap.status('INBOX', ["UIDNEXT"])["UIDNEXT"]
    last_uid = (next_uid > 1) ? next_uid - 1 : 1
    imap_cnd = st.value.blank? ? ['RECENT'] : ['UID', "#{st.value.to_i + 1}:#{last_uid}", 'UNSEEN']
    
    error = nil
    begin
      if filters.size > 0
        idx = 0
        timeout = Sys::Lib::Timeout.new(60)
        uids = Gw::WebmailMail.find_uid(:all, select: 'INBOX', conditions: imap_cnd)
        while (filtered = uids[idx, NUMBER_OF_FILTERED_UIDS]) && filtered.size > 0
          timeout.check
          apply_uids(filtered, select: 'INBOX', filters: filters)
          idx += filtered.size
        end        
      end
    rescue Sys::Lib::Timeout::Error => ex
      error = ex
    end

    if last_uid.to_s != st.value.to_s
      st.value = last_uid
      st.save(validate: false)
      return last_uid, true, error
    end
    return last_uid, false, error
  end

  def self.apply_uids(uids, params)
    applied_uids = []
    matched = []
    mails = Gw::WebmailMail.fetch_for_filter(uids, params[:select])

    filters = params[:filters] || [params[:filter]]
    filters.each { |filter| matched << { filter: filter, uids: [] } }

    mails.each do |mail|
      filters.each_with_index do |filter, idx|
        filter_matched = false
        begin
          filter.conditions.each do |c|
            values = []
            case c.column
            when 'subject'
              values += [mail.subject]
            when 'from'
              values += [mail.friendly_from_addr]
            when 'to'
              values += mail.friendly_to_addrs
            end

            syntax = nil
            case c.inclusion
            when '<'
              syntax = '!( value =~ /#{Regexp.quote(c.value)}/i ).nil?'
            when '!<'
              syntax = '( value =~ /#{Regexp.quote(c.value)}/i ).nil?'
            when '=='
              syntax = '( value == c.value )'
            when '=~'
              syntax = '( value.to_s =~ /#{c.value}/im )'
            end
            next unless syntax

            m = false
            values.each do |value|
              if eval(syntax)
                m = true
                break
              end
            end

            if m == true
              filter_matched = true
              break if filter.conditions_chain == 'or'
            else
              filter_matched = false
              break if filter.conditions_chain == 'and'
            end
          end #/filter.conditions

          if filter_matched
            matched[idx][:uids] << mail.uid
            break
          end
        rescue => e
          error_log(e)  
        end
      end #/filters
    end #/mails

    matched.each do |m|
      next unless m[:uids].size > 0
      begin
        Gw::WebmailMailNode.delete_nodes(params[:select], m[:uids]) if params[:delete_cache]
        case m[:filter].action
        when "move"
          if Gw::WebmailMail.move_all(params[:select], m[:filter].mailbox, m[:uids])
            applied_uids += m[:uids]
          end
        when "delete"
          if Gw::WebmailMail.delete_all(params[:select], m[:uids])
            applied_uids += m[:uids]
          end
        end
      rescue => e
        error_log(e)
        next
      end
    end

    return applied_uids
  rescue => e
    error_log(e)
    return []
  end

  def last_condition
    Gw::WebmailFilterCondition.where(filter_id: id).order(sort_no: :desc).first
  end

  def self.register_spams(items)
    filter = self.where(user_id: Core.current_user.id, name: '* 迷惑メール').first_or_initialize do |f|
      f.state = 'enabled'
      f.sort_no = 0
      f.conditions_chain = 'or'
      f.action = 'delete'
      f.mailbox = ''
    end
    filter.save(validate: false) if filter.new_record?

    last_condition = filter.last_condition
    next_sort_no = last_condition ? last_condition.sort_no + 1 : 0

    items.each_with_index do |item, i|
      fcond = Gw::WebmailFilterCondition.where(
        user_id: Core.current_user.id,
        filter_id: filter.id,
        column: 'from',
        inclusion: '<',
        value: item.from_addr
      ).first_or_initialize(sort_no: next_sort_no + i)
      fcond.save(validate: false) if fcond.new_record?
    end

    spam_max_count = Joruri.config.application['webmail.filter_condition_max_count'] 

    cond = { user_id: Core.current_user.id, filter_id: filter.id}
    spam_count = Gw::WebmailFilterCondition.where(cond).count
    if spam_count > spam_max_count
      del_items = Gw::WebmailFilterCondition.where(cond).limit(spam_count - spam_max_count).order(:sort_no)
      Gw::WebmailFilterCondition.where(id: del_items.map(&:id)).delete_all
    end
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

  def in_conditions
    #dummy
  end

  def validate_conditions
    if "#{in_columns.values.join}#{in_inclusions.values.join}#{in_values.values.join}".blank?
      return errors.add(:in_conditions, :empty)
    end
    in_columns.each do |i, c|
      next if "#{c}#{in_inclusions[i]}#{in_values[i]}".blank?
      if c.blank? || in_inclusions[i].blank? || in_values[i].blank?
        return errors.add(:in_conditions, :invalid)
      end
      if in_inclusions[i] == '=~'
        begin
          timeout(1) { test = ("text" =~ /#{in_values[i]}/im) }
        rescue => e
          errors.add(:in_conditions, "を正しく入力してください。（正規表現　/#{in_values[i]}/）")
        end
      end
    end
  end

  def save_conditions
    return true if !in_columns.is_a?(Hash) && !in_columns.is_a?(Array)

    in_conds = []
    in_columns.each do |i, c|
      next if c.blank? || in_inclusions[i].blank? || in_values[i].blank?
      in_conds << { column: c, inclusion: in_inclusions[i], value: in_values[i] }
    end

    in_conds.each_with_index do |c, idx|
      cond = conditions[idx] || Gw::WebmailFilterCondition.new
      cond.attributes = {
        user_id:   user_id,
        filter_id: id,
        sort_no:   idx,
        column:    c[:column],
        inclusion: c[:inclusion],
        value:     c[:value]
      }
      cond.save
    end

    in_conds.size.upto(conditions.size) do |i|
      conditions[i].destroy if conditions[i]
    end

    conditions(true)
    true
  end
end
