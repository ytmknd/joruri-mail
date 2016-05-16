class Gw::WebmailMailNode < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  validates :user_id, :uid, :mailbox, presence: true

  scope :readable, ->(user = Core.current_user) { where(user_id: user.id) }
  
  def self.find_nodes(boxname, uids = nil)
    items = Gw::WebmailMailNode.where(user_id: Core.current_user.id, mailbox: boxname)
    items = items.where(uid: uids) if uids
    items
  end

  def self.find_nodes_with_ref(boxname, uids = nil)
    items = Gw::WebmailMailNode.where(user_id: Core.current_user.id, mailbox: boxname)
    items = items.where.not(ref_mailbox: nil, ref_uid: nil)
    items = items.where(uid: uids) if uids
    items
  end

  def self.find_ref_nodes(boxname, uids = nil)
    items = Gw::WebmailMailNode.where(user_id: Core.current_user.id, ref_mailbox: boxname)
    items = items.where(ref_uid: uids) if uids
    items
  end

  def self.delete_nodes(boxname, uids = nil)
    Gw::WebmailMailNode.where(user_id: Core.current_user.id, mailbox: boxname, uid: uids).delete_all
  end

  def self.delete_ref_nodes(boxname, uids = nil)
    items = Gw::WebmailMailNode.where(user_id, Core.current_user.id, ref_mailbox: boxname)
    items = items.where(ref_uid: uids) if uids
    items.delete_all
  end

  def editable?
    Core.current_user.has_auth?(:manager) || user_id == Core.current_user.id
  end
  
  def deletable?
    Core.current_user.has_auth?(:manager) || user_id == Core.current_user.id
  end
end
