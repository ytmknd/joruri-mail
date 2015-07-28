# encoding: utf-8
class Gw::WebmailSign < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  validates_presence_of :user_id, :name
  
  after_save :uniq_default_flag, :if => %Q(default_flag == 1)

  def readable
    self.and :user_id, Core.user.id
    self
  end
  
  def editable?
    return true if Core.user.has_auth?(:manager)
    user_id == Core.user.id
  end
  
  def deletable?
    return true if Core.user.has_auth?(:manager)
    user_id == Core.user.id
  end
  
  def self.default_sign
    cond = {:user_id => Core.user.id, :default_flag => 1}
    self.find(:first, :conditions => cond)
  end

  def self.user_signs
    item = self.new.readable
    item.and :user_id, Core.user.id
    item.order 'name, id'
    item.find(:all)  
  end
  
protected
  def uniq_default_flag
    cond = Condition.new do |c|
      c.and :user_id, Core.user.id
      c.and :id, '!=', id
    end
    self.class.update_all('default_flag = 0', cond.where)
    return true
  end
end
