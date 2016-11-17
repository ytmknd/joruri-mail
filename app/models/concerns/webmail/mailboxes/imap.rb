require 'net/imap'
module Webmail::Mailboxes::Imap
  extend ActiveSupport::Concern

  SPECIAL_USE_MAILBOX_MAP = {
    # special use => mailbox name
    :Archive      => 'Archives',
    :Drafts       => 'Drafts',
    :Junk         => 'Junk',
    :Sent         => 'Sent',
    :Trash        => 'Trash',
    :All          => 'virtual.All',
    :Flagged      => 'virtual.Flagged',
  }.merge(Joruri.config.imap_settings[:mailbox_map].to_h)

  SPECIAL_USES = SPECIAL_USE_MAILBOX_MAP.keys
  REQUIRED_SPECIAL_USES = [:Archive, :Drafts, :Junk, :Sent, :Trash]
  ORDERS = Joruri.config.imap_settings[:mailbox_order] || %w(INBOX virtual Drafts Sent Archives Junk *** Trash)

  def create_mailbox(name)
    transaction do
      self.name = name
      self.save
      imap.create(name)
    end
  end

  def rename_mailbox(new_name)
    transaction do
      old_name = name
      self.name = new_name
      self.save
      imap.rename(old_name, new_name)
    end
  end

  def delete_mailbox
    transaction do
      self.destroy
      imap.delete(name)
    end
  end

  private

  def imap
    Core.imap
  end

  class_methods do
    def decode_name(name, delim)
      names = Net::IMAP.decode_utf7(name).split(delim)
      if names[0]
        I18n.t('webmail.mailbox.titles').each do |path, title|
          names[1] = title if names[0] == 'virtual' && names[1] == path.to_s
          names[0] = title if names[0] == path.to_s
        end
      end
      names.join(delim)
    end

    def load_mailbox(mailbox)
      unless item = self.find_by(user_id: Core.current_user.id, name: mailbox)
        sync_mailboxes([mailbox])
        item = self.find_by(user_id: Core.current_user.id, name: mailbox)
      end
      item
    end

    def load_mailboxes(reloads = nil)
      reloads = Array(reloads)
      items = self.where(user_id: Core.current_user.id).order(:sort_no).to_a
      reloads << :all if items.size < REQUIRED_SPECIAL_USES.size

      if reloads.present?
        ApplicationRecord.lock_by_name(Core.current_user.account) do
          sync_mailboxes(reloads)
        end
        items = self.where(user_id: Core.current_user.id).order(:sort_no)
      end

      make_tree(items)
    end

    def sync_mailboxes(reloads = [:all])
      items = self.where(user_id: Core.current_user.id).order(:sort_no)
      boxes, statuses = imap_sorted_list_and_status(reloads)

      status_by_name = statuses.index_by(&:mailbox)
      item_by_name = items.index_by(&:name)

      deleted_box_names = items.map(&:name) - boxes.map(&:name)
      deleted_box_names.each { |name| item_by_name[name].destroy if item_by_name[name] }

      boxes.each_with_index do |box, idx|
        item = item_by_name[box.name] || self.new
        item.attributes = {
          user_id:  Core.current_user.id,
          sort_no:  idx + 1,
          name:     box.name,
          title:    decode_name(box.name, box.delim).split(box.delim).last,
          delim:    box.delim,
          attr:     box.attr.join(' '),
          special_use: box.special_use,
        }
        if status = status_by_name[box.name]
          item.attributes = {
            messages: status.attr['MESSAGES'],
            unseen:   status.attr['UNSEEN'],
            recent:   status.attr['RECENT']
          }
        end
        item.save(validate: false) if item.changed?
      end
    end

    private

    def imap
      Core.imap
    end

    def imap_sorted_list_and_status(targets = [:all])
      boxes, statuses = imap_list_status(targets, ['MESSAGES', 'UNSEEN', 'RECENT'])

      needs = REQUIRED_SPECIAL_USES - boxes.map { |box| box.special_use }
      if needs.size > 0
        needs.each { |need| imap.create(SPECIAL_USE_MAILBOX_MAP[need]) }
        return imap_sorted_list_and_status(targets)
      end

      return sort_list(boxes), statuses
    end

    def imap_list_status(targets, returns)
      boxes = imap.list('', '*')
      boxes = append_special_use_flag(boxes)

      if imap.capabilities.include?('LIST-STATUS')
        _, statuses = imap.list_status('', '*', returns)
        statuses.reject! {|status| !targets.include?(status.mailbox) } unless targets.include?(:all)
      else
        statuses = []
        boxes.each do |box|
          if targets.include?(:all) || targets.include?(box.name)
            status = imap.status(box.name, returns)
            statuses << Net::IMAP::StatusData.new(box.name, status)
          end
        end
      end
      return boxes, statuses
    end

    def append_special_use_flag(boxes)
      box_by_name = boxes.index_by(&:name)
      specials = SPECIAL_USES - boxes.map { |box| box.special_use }
      specials.each do |special|
        box = box_by_name[SPECIAL_USE_MAILBOX_MAP[special]]
        box.special_use = special.to_sym if box
      end
      boxes
    end

    def sort_list(boxes)
      boxes = boxes.sort { |a, b| decode_name(a.name, a.delim).downcase <=> decode_name(b.name, b.delim).downcase }
      boxes = boxes.group_by do |box|
        name = box.name.split(box.delim).first
        name.in?(ORDERS) ? name : '***'
      end
      ORDERS.map { |name| boxes[name] }.compact.flatten
    end

    def make_tree(items)
      hash = items.index_by(&:name)
      items.each do |item|
        if item.ancestor_name && hash[item.ancestor_name]
          hash[item.ancestor_name].children.push(item)
          item.parent = hash[item.ancestor_name]
        end
      end
      items
    end
  end
end
