require 'net/imap'
class Gw::WebmailMailbox < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  DEFAULTS = %w(Drafts Sent Archives Trash Star)
  ORDERS = %w(INBOX Star Drafts Sent Archives virtual _etc Trash)

  attr_accessor :path
  attr_accessor :parent, :children

  validates :title, presence: true
  validate :validate_title

  scope :readable, ->(user = Core.current_user) { where(user_id: user.id) }

  def creatable?
    Core.current_user.has_auth?(:manager) || user_id == Core.current_user.id
  end

  def editable?
    Core.current_user.has_auth?(:manager) || user_id == Core.current_user.id
  end

  def deletable?
    Core.current_user.has_auth?(:manager) || user_id == Core.current_user.id
  end

  def draft_box?(target = :all)
    case target
    when :all      ; name =~ /^Drafts(\.|$)/
    when :children ; name =~ /^Drafts\./
    else           ; name == "Drafts"
    end
  end

  def sent_box?(target = :all)
    case target
    when :all      ; name =~ /^Sent(\.|$)/
    when :children ; name =~ /^Sent\./
    else           ; name == "Sent"
    end
  end

  def trash_box?(target = :all)
    case target
    when :all      ; name =~ /^Trash(\.|$)/
    when :children ; name =~ /^Trash\./
    else           ; name == "Trash"
    end
  end

  def star_box?(target = :all)
    case target
    when :all      ; name =~ /^Star(\.|$)/
    when :children ; name =~ /^Star\./
    else           ; name == "Star"
    end
  end

  def virtual_box?(target = :all)
    case target
    when :all      ; name =~ /^virtual(\.|$)/
    when :children ; name =~ /^virtual\./
    else           ; name == "virtual"
    end
  end

  def path
    return @path if @path
    return "" if name !~ /\./
    name.gsub(/(.*\.).*/, '\\1')
  end

  def slashed_title(char = "　 ")
    self.class.name_to_title(name).gsub('.', '/')
  end

  def indented_title(char = "　 ")
    "#{char * level_no}#{title}"
  end

  def root?
    #name.index('.').nil?
    parent.nil?
  end

  def names
    name.split('.')
  end

  def parent_name
    names[-2]
  end

  def ancestor_name
    ancestor_names.join('.')
  end

  def ancestor_names
    names[0..-2]
  end

  def level_no
    if virtual_box?
      names.count - 2
    else
      names.count - 1
    end
  end

  def special_box?
    name =~ Regexp.union(/^(INBOX|Drafts|Sent|Archives|Trash|Star|virtual)$/, /^virtual\./)
  end

  def creatable_child_box?
    name !~ /^(Drafts|Trash|Star|virtual)(\.|$)/
  end

  def editable_box?
    name !~ Regexp.union(/^(INBOX|Drafts|Sent|Archives|Trash|Star)$/, /^virtual(\.|$)/)
  end

  def deletable_box?
    editable_box?
  end

  def selectable_as_parent?
    name !~ /^(Drafts|Trash|Star|virtual)(\.|$)/
  end

  def mail_droppable_box?
    name !~ /^(Drafts|Star|virtual)(\.|$)/
  end

  def mail_movable_box?
    name !~ /^(Drafts|Trash|Star|virtual)(\.|$)/
  end

  def mail_unseen_count_box?
    name !~ /^(Drafts|Sent|Trash|Star|virtual)(\.|$)/
  end

  def filter_targetable_box?
    name !~ Regexp.union(/^(Drafts|Sent|Trash|Star|virtual)(\.|$)/, /^INBOX$/)
  end

  def filter_appliable_box?
    name !~ /^(Drafts|Sent|Trash|Star|virtual)(\.|$)/
  end

  def batch_deletable_box?
    name !~ /^(Star|virtual)(\.|$)/
  end

  private

  def validate_title
    if title =~ /[\.\/\#\\]/
      errors.add :title, "に半角記号（ . / # \\ ）は使用できません。"
    end
  end

  class << self
    def imap
      Core.imap
    end

    def name_to_title(name)
      name = Net::IMAP.decode_utf7(name)
      I18n.t('webmail.mailbox.titles').each do |key, title|
        name = name.gsub(/^#{key}(\.|$)/, title + '\1')
      end
      name
    end

    def imap_sorted_list_and_status(status_mailboxes = [:all], returns = ['MESSAGES', 'UNSEEN', 'RECENT'])
      boxes, statuses = imap_list_status(status_mailboxes, returns)

      need_boxes = DEFAULTS - boxes.map(&:name)
      if need_boxes.size > 0
        need_boxes.each { |box| imap.create(box) }
        imap_sorted_list_and_status(status_mailboxes, returns)
      end

      return sort_list(boxes), statuses
    end

    def imap_list_status(status_mailboxes = [:all], returns = ['MESSAGES', 'UNSEEN', 'RECENT'])
      nonexistent_or_noselect = ->(attr) {
        attr.in?([:Nonexistent, :Noselect])
      }

      if imap.capabilities.include?('LIST-STATUS')
        boxes, statuses = imap.list_status('', '*', returns)
        boxes.reject! { |box| box.attr.any?(&nonexistent_or_noselect) }
        statuses.reject! {|status| !status_mailboxes.include?(status.mailbox) } unless status_mailboxes.include?(:all)
      else
        boxes = imap.list('', '*')
        boxes.reject! { |box| box.attr.any?(&nonexistent_or_noselect) }
        statuses = []
        boxes.each do |box|
          if status_mailboxes.include?(:all) || status_mailboxes.include?(box.name)
            status = imap.status(box.name, returns)
            statuses << Net::IMAP::StatusData.new(box.name, status)
          end
        end
      end
      return boxes, statuses
    end

    def sort_list(boxes)
      boxes = boxes.sort { |a, b| name_to_title(a.name).downcase <=> name_to_title(b.name).downcase }
      boxes = boxes.group_by do |box|
        name = box.name.split('.').first
        name.in?(ORDERS) ? name : '_etc'
      end
      ORDERS.map { |name| boxes[name] }.compact.flatten
    end

    def load_mailbox(mailbox)
      unless box = self.find_by(user_id: Core.current_user.id, name: mailbox)
        sync_mailboxes([mailbox])
        box = self.find_by(user_id: Core.current_user.id, name: mailbox)
      end
      box
    end

    def load_mailboxes(reloads = nil)
      reloads = Array(reloads)
      boxes = self.where(user_id: Core.current_user.id).order(:sort_no)

      if reloads.present? || boxes.size == 0
        Util::Database.lock_by_name(Core.current_user.account) do
          sync_mailboxes(reloads)
        end
        boxes = self.where(user_id: Core.current_user.id).order(:sort_no)
      end

      make_tree(boxes)
    end

    def sync_mailboxes(reloads = [:all])
      boxes = self.where(user_id: Core.current_user.id).order(:sort_no)
      list_boxes, statuses = imap_sorted_list_and_status(reloads)

      status_by_name = statuses.index_by(&:mailbox)
      box_by_name = boxes.index_by(&:name)

      deleted_box_names = boxes.map(&:name) - list_boxes.map(&:name)
      deleted_box_names.each { |name| box_by_name[name].destroy if box_by_name[name] }

      list_boxes.each_with_index do |list_box, idx|
        if status = status_by_name[list_box.name]
          box = box_by_name[list_box.name]  || self.new
          box.attributes = {
            user_id:  Core.current_user.id,
            sort_no:  idx + 1,
            name:     list_box.name,
            title:    name_to_title(list_box.name).split('.').last,
            messages: status.attr['MESSAGES'],
            unseen:   status.attr['UNSEEN'],
            recent:   status.attr['RECENT']
          }
          box.save(validate: false) if box.changed?
        end
      end
    end

    def load_starred_mails(mailbox_uids = nil)
      return if mailbox_uids == nil

      imap.select('Star')
      unstarred_uids = imap.uid_search(['UNDELETED', 'UNFLAGGED'])
      if unstarred_uids.present?
        num = imap.uid_store(unstarred_uids, '+FLAGS', [:Deleted]).to_a.size
        if num > 0
          imap.expunge
          Gw::WebmailMailNode.delete_nodes('Star', unstarred_uids)
        end
      end

      mailbox_uids.each do |mailbox, uids|
        next if mailbox =~ /^(Star)$/

        current_starred_uids = Gw::WebmailMailNode.find_ref_nodes(mailbox).map{|x| x.ref_uid}

        imap.select(mailbox)
        if uids.empty? || uids.include?('all') ||  uids.include?(:all)
          new_starred_uids = imap.uid_search(['UNDELETED', 'FLAGGED'])
        else
          new_starred_uids = imap.uid_search(['UID', uids, 'UNDELETED', 'FLAGGED'])
        end
        new_starred_uids = new_starred_uids.select{|x| !current_starred_uids.include?(x) }
        next if new_starred_uids.blank?

        imap.select('Star')
        next_uid = imap.status('Star', ['UIDNEXT'])['UIDNEXT']

        imap.select(mailbox)
        res = imap.uid_copy(new_starred_uids, 'Star')
        next if res.name != 'OK'

        # create cache
        items = Gw::WebmailMail.fetch((next_uid..next_uid+new_starred_uids.size).to_a, 'Star')
        items.each_with_index do |item, i|
          if item.node
            item.node.ref_mailbox = mailbox
            item.node.ref_uid = new_starred_uids[i]
            item.node.save
          end
        end
      end
    end

    def load_quota(reload = false)
      st = Gw::WebmailSetting.where(user_id: Core.current_user.id, name: 'quota_info').first_or_initialize

      if !reload && st.persisted?
        quota = Hash.from_xml(st.value) || {}
        return quota.deep_symbolize_keys[:item]
      end

      if quota = get_quota_info
        st.value = quota.to_xml(dasherize: false, skip_types: true, root: 'item')
        st.save(validate: false)
      end
      quota
    end

    def get_quota_info
      return unless imap.capabilities.include?('QUOTA')

      res = imap.getquotaroot('INBOX')[1]
      return unless res

      usage_bytes = res.usage.to_i*1024
      quota_bytes = res.quota.to_i*1024
      warn_bytes = quota_bytes * Joruri.config.application['webmail.mailbox_quota_alert_rate'].to_f
      
      Hash.new.tap do |quota|
        number_to_human_size = ApplicationController.helpers.method(:number_to_human_size)
        size_options = { precision: 0, locale: :en }
        quota[:total_bytes] = quota_bytes
        quota[:total]       = number_to_human_size.call(quota_bytes, size_options)
        quota[:used_bytes]  = usage_bytes
        quota[:used]        = number_to_human_size.call(usage_bytes, size_options)
        quota[:usage_rate]  = sprintf('%.1f', usage_bytes.to_f / quota_bytes.to_f * 100).to_f
        quota[:usable]      = number_to_human_size.call(quota_bytes - usage_bytes, size_options) if usage_bytes > warn_bytes 
      end
    end

    def make_tree(mailboxes)
      mailboxes.each do |box|
        box.children = []
        box.parent = nil
      end
      hash = mailboxes.index_by(&:name)
      mailboxes.each do |box|
        if box.ancestor_name && hash[box.ancestor_name]
          hash[box.ancestor_name].children.push(box)
          box.parent = hash[box.ancestor_name]
        end
      end
      mailboxes
    end

    def mailbox_options(mailboxes = self.load_mailboxes, &block)
      mailboxes.select { |box| block.nil? || block.call(box) }
        .map {|box| [box.slashed_title, box.name] }
    end
  end
end
