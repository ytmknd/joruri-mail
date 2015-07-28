# encoding: utf-8
class Sys::LdapSynchro < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Tree
  include Sys::Model::Auth::Manager
  
  validates_presence_of :version, :entry_type, :code, :name
  
  def children
    return @_children if @_children
    cond = {:version => version, :parent_id => id, :entry_type => 'group'}
    @_children = self.class.find(:all, :conditions => cond, :order => 'sort_no, code')
  end
  
  def users
    return @_users if @_users
    cond = {:version => version, :parent_id => id, :entry_type => 'user'}
    @_users = self.class.find(:all, :conditions => cond, :order => 'sort_no, code')
  end
  
  def group_count
    cond = {:version => version, :entry_type => 'group'}
    self.class.count(:conditions => cond)
  end
  
  def user_count
    cond = {:version => version, :entry_type => 'user'}
    self.class.count(:conditions => cond)
  end
  
  def self.create_synchro(version = Time.now.to_i)
    @version = version
    @results = {:group => 0, :gerr => 0, :user => 0, :uerr => 0}
    
    self.create_synchros
    
    @results
  end
  
  def self.synchronize(version)
    @version = version
    @results = {:group => 0, :gerr => 0, :user => 0, :uerr => 0, :udel => 0, :gdel => 0, :error => ''}
    
    item = Sys::LdapSynchro.new
    item.and :version, @version
    item.and :parent_id, 0
    item.and :entry_type, 'group'
    items = item.find(:all, :order => 'sort_no, code')
    
    unless parent = Sys::Group.find_by_parent_id(0)
      raise "グループのRootが見つかりません。"
    end
    
    Sys::Group.update_all("ldap_version = NULL")
    Sys::User.update_all("ldap_version = NULL")
    
    items.each {|group| do_synchro(group, parent)}
    
    @results[:udel] = Sys::User.destroy_all("ldap = 1 AND ldap_version IS NULL").size
    @results[:gdel] = Sys::Group.destroy_all("parent_id != 0 AND ldap = 1 AND ldap_version IS NULL").size
    
    @results
  end
  
protected
  
  def self.create_synchros(entry = nil, group_id = nil)
    if entry.nil?
      Core.ldap.group.children.each do |e|
        create_synchros(e, 0)
      end
      return true
    end
    
    group = Sys::LdapSynchro.new({
      :parent_id    => group_id,
      :version      => @version,
      :entry_type   => 'group',
      :code         => entry.code,
      :name         => entry.name,
      :name_en      => entry.name_en,
      :email        => entry.email,
      :group_s_name => entry.group_s_name,
    })
    if group.save
      @results[:group] += 1
    else
      @results[:gerr] += 1
      return false
    end
    
    entry.users.each do |e|
      user = Sys::LdapSynchro.new({
        :parent_id         => group.id,
        :version           => @version,
        :entry_type        => 'user',
        :code              => e.uid,
        :name              => e.name,
        :name_en           => e.name_en,
        :email             => e.email,
        :kana              => e.kana,
        :sort_no           => e.sort_no,
        :official_position => e.official_position,
        :assigned_job      => e.assigned_job,
        :group_s_name      => e.group_s_name
      })
      if user.save
        @results[:user] += 1
      else
        @results[:uerr] += 1
      end
    end
    
    entry.children.each do |e|
      create_synchros(e, group.id)
    end
  end
  
  def self.do_synchro(group, parent = nil)
    ## group
    sg                = Sys::Group.find_by_code(group.code) || Sys::Group.new
    sg.code           = group.code
    sg.parent_id      = parent.id
    sg.state        ||= 'enabled'
    sg.web_state    ||= 'public'
    sg.name           = group.name
    sg.name_en        = group.name_en if !group.name_en.blank?
    sg.email          = group.email if !group.email.blank?
    sg.group_s_name   = group.group_s_name
    sg.level_no       = parent.level_no + 1
    #sg.sort_no        = group.sort_no
    sg.ldap         ||= 1
    sg.ldap_version   = group.version
    
    if sg.ldap == 1
      if sg.save(:validate => false)
        @results[:group] += 1
      else
        @results[:gerr] += 1
        return false
      end
    end
    
    ## users
    if group.users.size > 0
      group.users.each do |user|
        su                   = Sys::User.find_by_account(user.code) || Sys::User.new
        su.account           = user.code
        su.state           ||= 'enabled'
        su.auth_no         ||= 2
        su.name              = user.name
        su.name_en           = user.name_en
        su.email             = user.email
        su.kana              = user.kana
        su.sort_no           = user.sort_no
        su.official_position = user.official_position
        su.assigned_job      = user.assigned_job
        su.group_s_name      = user.group_s_name
        su.ldap            ||= 1
        su.ldap_version      = user.version
        su.in_group_id       = sg.id
        
        if su.ldap == 1
          if su.save
            @results[:user] += 1
          else
            @results[:uerr] += 1
          end
        end
      end
    end
    
    ## next
    if group.children.size > 0
      group.children.each {|g| do_synchro(g, sg)}
    end
  end
end
