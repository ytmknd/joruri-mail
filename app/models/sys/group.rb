# encoding: utf-8
class Sys::Group < Sys::ManageDatabase
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Tree
  include Sys::Model::Auth::Manager
  
  belongs_to :status    , :foreign_key => :state    , :class_name => 'Sys::Base::Status'
  belongs_to :web_status, :foreign_key => :web_state, :class_name => 'Sys::Base::Status'
  belongs_to :parent    , :foreign_key => :parent_id, :class_name => 'Sys::Group'
###  belongs_to :layout    , :foreign_key => :layout_id, :class_name => 'Cms::Layout'
  
  has_many :children  , :foreign_key => :parent_id, :class_name => 'Sys::Group',
    :order => :sort_no, :dependent => :destroy
  has_many :enabled_children  , :foreign_key => :parent_id, :class_name => 'Sys::Group',
    :conditions => {:state => 'enabled'},
    :order => :sort_no, :dependent => :destroy

  has_many :users_groups, :foreign_key => :group_id
  has_many :users, :through => :users_groups, :source => :user, 
    :order => 'sys_users.email, sys_users.account'
  has_many :ldap_users, :through => :users_groups, :source => :user, 
    :conditions => {:ldap => 1, :state => 'enabled'},
    :order => 'sys_users.email, sys_users.account'
  has_many :enabled_users, :through => :users_groups, :source => :user, 
    :conditions => {:state => 'enabled'},
    :order => 'sys_users.email, sys_users.account'

  validates_presence_of :state, :level_no, :code, :name, :name_en, :ldap
  validates_uniqueness_of :code
  
  attr_accessor :call_update_child_level_no
  after_save :update_child_level_no
  before_destroy :disable_users
  
  def ldap_users_having_email(order = "id")
    self.ldap_users.find(:all, :conditions => ["email IS NOT NULL AND email != ''"], :order => order)
  end

  def count_ldap_users_having_email
    self.ldap_users.count(:all, :conditions => ["email IS NOT NULL AND email != ''"])
  end
  
  def enabled_users_having_email(order = "id")
    self.enabled_users.find(:all, :conditions => ["email IS NOT NULL AND email != ''"], :order => order)
  end
  
  def count_enabled_users_having_email
    self.enabled_users.count(:all, :conditions => ["email IS NOT NULL AND email != ''"])
  end
  
  def self.show_only_ldap_user
    Joruri.config.application['webmail.show_only_ldap_user'] == 1
  end
  
  def users_having_email(order = "id")
    if Sys::Group.show_only_ldap_user
      ldap_users_having_email(order)
    else
      enabled_users_having_email(order)
    end
  end
  
  def count_users_having_email
    if Sys::Group.show_only_ldap_user
      count_ldap_users_having_email
    else
      count_enabled_users_having_email
    end
  end
  
  def readable
    self
  end
  
  def creatable?
    Core.user.has_auth?(:manager)
  end
  
  def readable?
    Core.user.has_auth?(:manager)
  end
  
  def editable?
    Core.user.has_auth?(:manager)
  end
  
  def deletable?
    Core.user.has_auth?(:manager)
  end
  
  def ldap_states
    [['同期',1],['非同期',0]]
  end
  
  def web_states
    [['公開','public'],['非公開','closed']]
  end
  
  def ldap_label
    ldap_states.each {|a| return a[0] if a[1] == ldap }
    return nil
  end
  
  def ou_name
    "#{code}#{name}"
  end
  
  def full_name
    n = name
    n = "#{parent.name}　#{n}" if parent && parent.level_no > 1
    n
  end
  
  def candidate(include_top = false)
    choices = []
    
    down = lambda do |p, i|
      if new_record? || p.id != id
        choices << [('　　' * i) + p.name, p.id]
        p.children.each {|child| down.call(child, i + 1)}
      end
    end

    group = self.class.new
    group.and 'level_no', 1
    top = group.find(:first)
    if include_top
      roots = [top]
    else
      roots = top.children 
    end
    roots.each {|i| down.call(i, 0)}
    
    choices
  end
  
private
  def disable_users
    users.each do |user|
      if user.groups.size == 1
        u = Sys::User.find_by_id(user.id)
        u.state = 'disabled'
        u.save
      end
    end
    return true
  end

  def update_child_level_no
    if call_update_child_level_no && level_no_changed?
      children.each do |c|
        c.level_no = level_no + 1
        c.call_update_child_level_no = true
        c.save(:validate => false)
      end
    end
  end
end
