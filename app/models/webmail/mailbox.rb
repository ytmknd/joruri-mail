class Webmail::Mailbox < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Auth::Free
  include Webmail::Mailboxes::Imap
  include Webmail::Mailboxes::Mail

  attr_accessor :path
  attr_accessor :parent, :children

  validates :title, presence: true
  validate :validate_title

  after_initialize :set_defaults

  with_options if: "name.present? && name_changed?" do
    before_update :update_filters
    before_update :update_mail_nodes
    before_update :update_children
  end

  with_options if: "name.present?" do
    before_destroy :disable_filters
    before_destroy :destroy_mail_nodes
    before_destroy :destroy_children
  end

  def filters
    Webmail::Filter.where(user_id: user_id, mailbox_name: name)
  end

  def mail_nodes
    Webmail::MailNode.where(user_id: user_id, mailbox: name)
  end

  def creatable?
    Core.current_user.has_auth?(:manager) || user_id == Core.current_user.id
  end

  def editable?
    Core.current_user.has_auth?(:manager) || user_id == Core.current_user.id
  end

  def deletable?
    Core.current_user.has_auth?(:manager) || user_id == Core.current_user.id
  end

  def attrs
    @attrs ||= attr.to_s.split(' ')
  end

  def noselect?
    attrs.include?('Noselect')
  end

  def nonexistent?
    attrs.include?('Nonexistent')
  end

  def noinferiors?
    attrs.include?('Noinferiors')
  end

  def path
    return @path if @path
    names[0..-2].present? ? names[0..-2].join(delim) + delim : ''
  end

  def path_and_encoded_title
    path + Net::IMAP.encode_utf7(title)
  end

  def slashed_title
    self.class.decode_name(name, delim).gsub(delim, '/')
  end

  def indented_title(char = "　 ")
    "#{char * level_no}#{title}"
  end

  def names
    name.split(delim)
  end

  def parent_name
    names[-2]
  end

  def name_with_delim
    "#{name}#{delim}"
  end

  def root?
    #name.index('.').nil?
    parent.nil?
  end

  def ancestors(items = [])
    parent.ancestors(items) if parent
    items << self
  end

  def descendants(items = [])
    items << self
    children.each {|c| c.descendants(items) }
    items
  end

  def ancestor_name
    ancestor_names.join(delim)
  end

  def ancestor_names
    names[0..-2]
  end

  def level_no
    names.count - 1
  end

  def inbox?
    name.upcase == 'INBOX'
  end

  def virtual?
    name.downcase == 'virtual'
  end

  def use_as_archive?
    special_use == 'Archive'
  end

  def use_as_drafts?
    special_use == 'Drafts'
  end

  def use_as_sent?
    special_use == 'Sent'
  end

  def use_as_junk?
    special_use == 'Junk'
  end

  def use_as_trash?
    special_use == 'Trash'
  end

  def use_as_all?
    special_use == 'All'
  end

  def use_as_flagged?
    special_use == 'Flagged'
  end

  def archive_box?(target = :all)
    in_special_use_box?(target, 'Archive')
  end

  def draft_box?(target = :all)
    in_special_use_box?(target, 'Drafts')
  end

  def junk_box?(target = :all)
    in_special_use_box?(target, 'Junk')
  end

  def sent_box?(target = :all)
    in_special_use_box?(target, 'Sent')
  end

  def trash_box?(target = :all)
    in_special_use_box?(target, 'Trash')
  end

  def all_box?(target = :all)
    in_special_use_box?(target, 'All')
  end

  def flagged_box?(target = :all)
    in_special_use_box?(target, 'Flagged')
  end

  def virtual_box?(target = :all)
    in_special_name_box?(target, 'virtual')
  end

  def in_special_use_box?(target, special_use)
    has_special_ancestor = ancestors.any? {|box| box.special_use == special_use }
    case target
    when :all      ; has_special_ancestor
    when :children ; has_special_ancestor && self.special_use != special_use
    end
  end

  def in_special_name_box?(target, name)
    has_special_ancestor = ancestors.any? {|box| box.name.downcase == name.downcase }
    case target
    when :all      ; has_special_ancestor
    when :children ; has_special_ancestor && self.name.downcase != name.downcase
    end
  end

  def creatable_child_box?
    !(draft_box? || junk_box? || trash_box? || all_box? || flagged_box? || virtual_box? || noinferiors?)
  end

  def editable_box?
    !(inbox? || special_use.present? || virtual_box? || noselect?)
  end

  def deletable_box?
    editable_box?
  end

  def selectable_as_parent?
    !(draft_box? || junk_box? || trash_box? || all_box? || flagged_box? || virtual_box?)
  end

  def mail_droppable_box?
    !(draft_box? || all_box? || flagged_box? || virtual_box?)
  end

  def mail_movable_box?
    !(draft_box? || trash_box? || all_box? || flagged_box? || virtual_box?)
  end

  def mail_unseen_count_box?
    !(draft_box? || sent_box? || trash_box? || all_box? || flagged_box? || virtual_box?)
  end

  def filter_targetable_box?
    !(inbox? || draft_box? || sent_box? || trash_box? || all_box? || flagged_box? || virtual_box?)
  end

  def filter_appliable_box?
    !(draft_box? || sent_box? || trash_box? || all_box? || flagged_box? || virtual_box?)
  end

  def batch_deletable_box?
    !(all_box? || flagged_box? || virtual_box?)
  end

  private

  def set_defaults
    self.children = []
  end

  def validate_title
    if title =~ /[\.\/\#\\]/
      errors.add :title, "に半角記号（ . / # \\ ）は使用できません。"
    end
  end

  def rename_path(name, old_name, new_name)
    name.gsub(/^#{Regexp.escape(old_name)}(#{Regexp.escape(delim)}|$)/, "#{new_name}\\1")
  end

  def update_filters
    Webmail::Filter.where(user_id: user_id, mailbox_name: name_was).each do |filter|
      filter.update_columns(mailbox_name: rename_path(filter.mailbox_name, name_was, name))
    end
  end

  def update_mail_nodes
    Webmail::MailNode.where(user_id: user_id, mailbox: name_was).update_all(mailbox: name)
  end

  def update_children
    children.each do |child|
      child.name = rename_path(child.name, name_was, name)
      child.save
    end
  end

  def disable_filters
    filters.update_all(state: 'disabled', mailbox_name: '')
  end

  def destroy_mail_nodes
    mail_nodes.delete_all
  end

  def destroy_children
    children.each(&:destroy)
  end

  class << self
    def mailbox_options(mailboxes = self.load_mailboxes, &block)
      mailboxes.select { |box| block.nil? || block.call(box) }
        .map {|box| [box.slashed_title, box.name] }
    end
  end
end
