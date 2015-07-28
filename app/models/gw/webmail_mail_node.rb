# encoding: utf-8
class Gw::WebmailMailNode < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  validates_presence_of :user_id, :uid, :mailbox
  
  def self.find_nodes(boxname, uids = nil)
    cond = Condition.new
    cond.and :user_id, Core.current_user.id
    cond.and :mailbox, boxname
    cond.and :uid, uids if uids
    Gw::WebmailMailNode.find(:all, :conditions => cond.where)
  end
  
  def self.find_nodes_with_ref(boxname, uids = nil)
    cond = Condition.new
    cond.and :user_id, Core.current_user.id
    cond.and :mailbox, boxname
    cond.and :uid, uids if uids
    cond.and :ref_mailbox, 'IS NOT ', nil
    cond.and :ref_uid, 'IS NOT ', nil
    Gw::WebmailMailNode.find(:all, :conditions => cond.where)
  end
  
  def self.find_ref_nodes(boxname, uids = nil)
    cond = Condition.new
    cond.and :user_id, Core.current_user.id
    cond.and :ref_mailbox, boxname
    cond.and :ref_uid, uids if uids
    Gw::WebmailMailNode.find(:all, :conditions => cond.where)
  end
  
  def self.delete_nodes(boxname, uids = nil)
    dcon = Condition.new do |c|
      c.and :user_id, Core.current_user.id
      c.and :mailbox, boxname
      if uids.is_a?(Array)
        c.and :uid, 'IN', uids 
      elsif uids
        c.and :uid, uids
      end
    end
    Gw::WebmailMailNode.delete_all(dcon.where)    
  end
  
  def self.delete_ref_nodes(boxname, uids = nil)
    cond = Condition.new
    cond.and :user_id, Core.current_user.id
    cond.and :ref_mailbox, boxname
    cond.and :ref_uid, uids if uids
    Gw::WebmailMailNode.delete_all(cond.where)
  end
  
  def readable
    self.and :user_id, Core.current_user.id
    self
  end
  
  def editable?
    return true if Core.current_user.has_auth?(:manager)
    user_id == Core.current_user.id
  end
  
  def deletable?
    return true if Core.current_user.has_auth?(:manager)
    user_id == Core.current_user.id
  end
end
