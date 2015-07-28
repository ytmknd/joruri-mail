# coding: utf-8
class Sys::UserLogin < ActiveRecord::Base
  include Sys::Model::Base

  belongs_to :user, :foreign_key => :user_id, :class_name => 'Sys::User'
  
  def self.put_log(user)
    login = self.new(:user_id => user.id)
    if login.save(:validate => false)
      delete_past(user)
    end
  end
  
  def self.delete_past(user)
    if (list = user.logins).size > 10
      delete_all(['user_id = ? and id < ?', user.id, list[9].id])
    end
    user.logins(true)
  end
  
  def login_at
    created_at  
  end
end