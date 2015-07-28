# encoding: utf-8
class System::User < System::Database
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Auth::Manager
  
  validates_length_of :mobile_password, :minimum => 4, :if => Proc.new{|u| u.mobile_password && u.mobile_password.length != 0}
  
  has_many :users_groups, :foreign_key => :user_id, :class_name => 'System::UsersGroup'
  has_many :groups, :through => :users_groups, :source => :user
  
end