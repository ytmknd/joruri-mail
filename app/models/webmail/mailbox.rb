class Webmail::Mailbox < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free
  include Webmail::Mailboxes::Imap

  attr_accessor :path
  attr_accessor :parent, :children

  validates :title, presence: true
  validate :validate_title

  scope :readable, ->(user = Core.current_user) { where(user_id: user.id) }

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
    Webmail::Filter.where(user_id: user_id, mailbox: name)
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

  def path_and_encoded_title
    path + Net::IMAP.encode_utf7(title)
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

  def set_defaults
    self.children = []
  end

  def validate_title
    if title =~ /[\.\/\#\\]/
      errors.add :title, "に半角記号（ . / # \\ ）は使用できません。"
    end
  end

  def rename_path(name, old_name, new_name)
    name.gsub(/^#{Regexp.escape(old_name)}(\.|$)/, "#{new_name}\\1")
  end

  def update_filters
    Webmail::Filter.where(user_id: user_id, mailbox: name_was).each do |filter|
      filter.update_columns(mailbox: rename_path(filter.mailbox, name_was, name))
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
    filters.update_all(state: 'disabled', mailbox: '')
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
