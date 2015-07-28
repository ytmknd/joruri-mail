# encoding: utf-8
require 'digest/sha1'
class Sys::User < Sys::ManageDatabase
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Rel::RoleName
  include Sys::Model::Auth::Manager

  belongs_to :status,     :foreign_key => :state,
    :class_name => 'Sys::Base::Status'
  has_many   :group_rels, :foreign_key => :user_id,
    :class_name => 'Sys::UsersGroup'  , :primary_key => :id
  has_many :users_groups, :foreign_key => :user_id
  has_many :groups, :through => :users_groups, :source => :group

  has_many :logins, :foreign_key => :user_id, :class_name => 'Sys::UserLogin',
    :order => 'id desc', :dependent => :delete_all
    
  has_many :webmail_mail_nodes, :foreign_key => :user_id, :class_name => 'Gw::WebmailMailNode',
    :order => 'id', :dependent => :destroy
  has_many :webmail_mailboxes, :foreign_key => :user_id, :class_name => 'Gw::WebmailMailbox',
    :order => 'id', :dependent => :destroy
  has_many :webmail_settings, :foreign_key => :user_id, :class_name => 'Gw::WebmailSetting',
    :order => 'id', :dependent => :destroy
  has_many :webmail_address_groups, :foreign_key => :user_id, :class_name => 'Gw::WebmailAddressGroup',
    :order => 'id', :dependent => :destroy
  has_many :webmail_addresses, :foreign_key => :user_id, :class_name => 'Gw::WebmailAddress',
    :order => 'id', :dependent => :destroy
  has_many :webmail_filters, :foreign_key => :user_id, :class_name => 'Gw::WebmailFilter',
    :order => 'id', :dependent => :destroy
  has_many :webmail_signs, :foreign_key => :user_id, :class_name => 'Gw::WebmailSign',
    :order => 'id', :dependent => :destroy
  has_many :webmail_templates, :foreign_key => :user_id, :class_name => 'Gw::WebmailTemplate',
    :order => 'id', :dependent => :destroy
  has_many :webmail_mail_address_histories, :foreign_key => :user_id, :class_name => 'Gw::WebmailMailAddressHistory',
    :order => 'id', :dependent => :destroy
  
  attr_accessor :in_group_id
  #attr_accessor :group, :group_id, :in_group_id
  
  validates_presence_of :state, :account, :name, :ldap
  validates_length_of :mobile_password, :minimum => 4, :if => Proc.new{|u| u.mobile_password && u.mobile_password.length != 0}
  validates_uniqueness_of :account
  
  after_save :save_group, :if => %Q(@_in_group_id_changed)

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
  
  def authes
    #[['なし',0], ['投稿者',1], ['作成者',2], ['編集者',3], ['設計者',4], ['管理者',5]]
    [['作成者',2], ['設計者',4], ['管理者',5]]
  end
  
  def auth_name
    authes.each {|a| return a[0] if a[1] == auth_no }
    return nil
  end
  
  def ldap_states
    [['同期',1],['非同期',0]]
  end
  
  def ldap_label
    ldap_states.each {|a| return a[0] if a[1] == ldap }
    return nil
  end
  
  def mobile_access_states
    [['不許可',0],['許可',1]]
  end
  
  def mobile_access_label
    mobile_access_states.each {|a| return a[0] if a[1] == mobile_access }
    return nil
  end
  
  def name_with_id
    "#{name}（#{id}）"
  end

  def name_with_account
    "#{name}（#{account}）"
  end
  
  def label(name)
    case name; when nil; end
  end
  
  def group(load = nil)
    return @group if @group && load
    @group = groups(load).size == 0 ? nil : groups[0]
  end
  
  def group_id(load = nil)
    (g = group(load)) ? g.id : nil
  end
  
  def in_group_id
    if read_attribute(:in_group_id).nil?
      write_attribute(:in_group_id, (group ? group.id : nil))
    end
    read_attribute(:in_group_id)
  end
  
  def in_group_id=(value)
    @_in_group_id_changed = true
    write_attribute(:in_group_id, value.to_s)
  end
  
  def has_auth?(name)
    auth = {
      :none     => 0, # なし  操作不可
      :reader   => 1, # 読者  閲覧のみ
      :creator  => 2, #作成者 記事作成者
      :editor   => 3, #編集者 データ作成者
      :designer => 4, #設計者 デザイン作成者
      :manager  => 5, #管理者 設定作成者
    }
    raise "Unknown authority name: #{name}" unless auth.has_key?(name)
    return auth[name] <= auth_no
  end

  def has_priv?(action, options = {})
    unless options[:auth_off]
      return true if has_auth?(:manager)
    end
    return nil unless options[:item]

    item = options[:item]
    if item.kind_of?(ActiveRecord::Base)
      item = item.unid
    end
    
    cond = {:action => action.to_s, :item_unid => item}
    roles = Sys::ObjectPrivilege.find(:all, :conditions => cond)
    return false if roles.size == 0
    
    cond = Condition.new do |c|
      c.and :user_id, id
      c.and :role_id, 'ON', roles.collect{|i| i.role_id}
    end
    Sys::UsersRole.find(:first, :conditions => cond.where)
  end

  def delete_group_relations
    Sys::UsersGroup.delete_all(:user_id => id)
    return true
  end
  
  def search(params)
    
    like_param = lambda do |s|
      s.gsub(/[\\%_]/) {|r| "\\#{r}"}
    end

    params.each do |n, vs|
      next if vs.to_s == ''
      vs.split(/[ 　]+/).each do |v|
        next if v == ''
        case n
        when 's_id'
          self.and :id, v
        when 's_state'
          self.and 'sys_users.state', v
        when 's_account'
          self.and 'sys_users.account', 'LIKE', "%#{like_param.call(v)}%"
        when 's_name'
          self.and 'sys_users.name', 'LIKE', "%#{like_param.call(v)}%"
        when 's_email'
          self.and 'sys_users.email', 'LIKE', "%#{like_param.call(v)}%"
        when 's_group_id'
          if v == 'no_group'
            self.join 'LEFT OUTER JOIN sys_users_groups ON sys_users_groups.user_id = sys_users.id' +
              ' LEFT OUTER JOIN sys_groups ON sys_users_groups.group_id = sys_groups.id'
            self.and 'sys_groups.id',  'IS', nil
          else
            self.join :groups
            self.and 'sys_groups.id', v
          end
        when 's_name_or_kana'
          kana_v = v.to_s.tr("ぁ-ん", "ァ-ン")
          cond = Condition.new
          cond.or 'sys_users.name', 'LIKE', "%#{like_param.call(v)}%"
          cond.or 'sys_users.kana', 'LIKE', "%#{like_param.call(kana_v)}%"
          self.and cond
        end
      end
    end if params.size != 0

    return self
  end

  def self.find_managers
    cond = {:state => 'enabled', :auth_no => 5}
    self.find(:all, :conditions => cond, :order => :id)
  end
  
  ## -----------------------------------
  ## Authenticates

  ## Authenticates a user by their account name and unencrypted password.  Returns the user or nil.
  def self.authenticate(in_account, in_password, encrypted = false)
    in_password = Util::String::Crypt.decrypt(in_password) if encrypted
    
    user = nil
    self.new.enabled.find(:all, :conditions => {:account => in_account, :state => 'enabled'}).each do |u|
      if u.ldap == 1
        ## LDAP Auth
        if Core.ldap.connection.bound?
          Core.ldap.connection.unbind
          Core.ldap = nil
        end
        
        next unless Core.ldap.bind(u.bind_dn, in_password)
        u.password = in_password
      else
        ## DB Auth
        next if in_password != u.password || u.password.to_s == ''
      end
      user = u
      break
    end
    return user
  end
  
  def bind_dn
    return false unless group = self.groups[0]
    
    group_path = group.parents_tree.reverse.select{|g| g.level_no > 1}
    ous = group_path.map{|g| "ou=#{g.ou_name}"}.join(',')
    
    Core.ldap.bind_dn
      .gsub("[base]", Core.ldap.base.to_s)
      .gsub("[domain]", Core.ldap.domain.to_s)
      .gsub("[uid]", self.account.to_s)
      .gsub("[ous]", ous.to_s)
  end
  
  def authenticate_mobile_password(_mobile_password)
    if mobile_access == 1
      if !mobile_password.to_s.empty? && mobile_password == _mobile_password
        return self
      end
    end
    return nil
  end
  
  def encrypt_password
    return if password.blank?
    Util::String::Crypt.encrypt(password)
  end
  
  def remember_token?
    remember_token_expires_at && Time.now.utc < remember_token_expires_at
  end

  def remember_me
    self.remember_token_expires_at = 2.weeks.from_now.utc
    self.remember_token            = encrypt("#{email}--#{remember_token_expires_at}")
    save(:validate => false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(:validate => false)
  end

  def previous_login_date
    return @previous_login_date if @previous_login_date
    if (list = logins.find(:all, :limit => 2)).size != 2
      return nil
    end
    @previous_login_date = list[1].login_at  
  end
  
protected
  def password_required?
    password.blank?
  end
  
  def save_group
    exists = (group_rels.size > 0)
    
    group_rels.each_with_index do |rel, idx|
      if idx == 0 && !in_group_id.blank?
        if rel.group_id != in_group_id
          cond = {:user_id => rel.user_id, :group_id => rel.group_id}
          rel.class.update_all({:group_id => in_group_id}, cond)
          rel.group_id = in_group_id
        end
      else
        rel.destroy
      end
    end
    
    if !exists && !in_group_id.blank?
      rel = Sys::UsersGroup.create({
        :user_id  => id,
        :group_id => in_group_id
      })
    end
    
    return true
  end
end
