require 'digest/sha1'
class Sys::User < Sys::ManageDatabase
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Auth::Manager

  belongs_to_active_hash :status, foreign_key: :state, class_name: 'Sys::Base::Status'
  has_many :group_rels, foreign_key: :user_id,
    class_name: 'Sys::UsersGroup', primary_key: :id
  has_many :users_groups, foreign_key: :user_id
  has_many :groups, through: :users_groups, source: :group

  has_many :logins, -> { order(id: :desc) },
    foreign_key: :user_id, class_name: 'Sys::UserLogin', dependent: :delete_all

  has_many :webmail_mail_nodes, -> { order(:id) },
    foreign_key: :user_id, class_name: 'Webmail::MailNode', dependent: :destroy
  has_many :webmail_mailboxes, -> { order(:id) },
    foreign_key: :user_id, class_name: 'Webmail::Mailbox', dependent: :destroy
  has_many :webmail_settings, -> { order(:id) },
    foreign_key: :user_id, class_name: 'Webmail::Setting', dependent: :destroy
  has_many :webmail_address_groups, -> { order(:id) },
    foreign_key: :user_id, class_name: 'Webmail::AddressGroup', dependent: :destroy
  has_many :webmail_addresses, -> { order(:id) },
    foreign_key: :user_id, class_name: 'Webmail::Address', dependent: :destroy
  has_many :webmail_filters, -> { order(:id) },
    foreign_key: :user_id, class_name: 'Webmail::Filter', dependent: :destroy
  has_many :webmail_signs, -> { order(:id) },
    foreign_key: :user_id, class_name: 'Webmail::Sign', dependent: :destroy
  has_many :webmail_templates, -> { order(:id) },
    foreign_key: :user_id, class_name: 'Webmail::Template', dependent: :destroy
  has_many :webmail_mail_address_histories, -> { order(:id) },
    foreign_key: :user_id, class_name: 'Webmail::MailAddressHistory', dependent: :destroy

  attr_accessor :_in_group_id
  #attr_accessor :group, :group_id, :in_group_id

  after_save :save_group, if: %Q(@_in_group_id_changed)

  validates :state, :account, :name, :ldap, presence: true
  validates :mobile_password, length: { minimum: 4, if: lambda { |u| u.mobile_password && u.mobile_password.length != 0 } }
  validates :account, uniqueness: true

  scope :readable, -> { all }
  scope :with_valid_email, -> { where.not(email: nil).where.not(email: '') }
  scope :search, ->(params) {
    rel = all
    params.each do |n, vs|
      next if vs.to_s == ''
      vs.split(/[ 　]+/).each do |v|
        next if v == ''
        case n
        when 's_id'
          rel = rel.where(id: v)
        when 's_state'
          rel = rel.where(state: v)
        when 's_account'
          rel = rel.where(arel_table[:account].matches("%#{escape_like(v)}%"))
        when 's_name'
          rel = rel.where(arel_table[:name].matches("%#{escape_like(v)}%"))
        when 's_email'
          rel = rel.where(arel_table[:email].matches("%#{escape_like(v)}%"))
        when 's_group_id'
          if v == 'no_group'
            rel = rel.eager_load(:groups).where(sys_groups: { id: nil })
          else
            rel = rel.joins(:groups).where(sys_groups: { id: v })
          end
        when 's_name_or_kana'
          kana_v = v.to_s.tr("ぁ-ん", "ァ-ン")
          rel = rel.where([
            arel_table[:name].matches("%#{escape_like(v)}%"),
            arel_table[:kana].matches("%#{escape_like(kana_v)}%")
          ].reduce(:or))
        end
      end
    end
    rel
  }

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
    authes.each { |a| return a[0] if a[1] == auth_no }
    return nil
  end

  def ldap_states
    [['同期',1],['非同期',0]]
  end

  def ldap_label
    ldap_states.each { |a| return a[0] if a[1] == ldap }
    return nil
  end

  def mobile_access_states
    [['不許可',0],['許可',1]]
  end

  def mobile_access_label
    mobile_access_states.each { |a| return a[0] if a[1] == mobile_access }
    return nil
  end

  def name_with_id
    "#{name}（#{id}）"
  end

  def name_with_account
    "#{name}（#{account}）"
  end

  def email_format
    "#{Email.quote_phrase(name)} <#{email}>"
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
    if _in_group_id.nil?
      self._in_group_id = (group ? group.id : nil)
    end
    _in_group_id
  end

  def in_group_id=(value)
    @_in_group_id_changed = true
    self._in_group_id = value.to_s
  end

  def has_auth?(name)
    auth = {
      none:     0, # なし  操作不可
      reader:   1, # 読者  閲覧のみ
      creator:  2, #作成者 記事作成者
      editor:   3, #編集者 データ作成者
      designer: 4, #設計者 デザイン作成者
      manager:  5, #管理者 設定作成者
    }
    raise "Unknown authority name: #{name}" unless auth.has_key?(name)
    return auth[name] <= auth_no
  end

  def delete_group_relations
    Sys::UsersGroup.where(user_id: id).delete_all
    return true
  end

  def self.find_managers
    self.where(state: 'enabled', auth_no: 5).order(:id)
  end

  ## -----------------------------------
  ## Authenticates

  ## Authenticates a user by their account name and unencrypted password.  Returns the user or nil.
  def self.authenticate(in_account, in_password, encrypted = false)
    in_password = Util::String::Crypt.decrypt(in_password) if encrypted

    user = nil
    self.where(account: in_account, state: 'enabled').each do |u|
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

    group_path = group.ancestors.reverse.select { |g| g.level_no > 1 }
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
    save(validate: false)
  end

  def forget_me
    self.remember_token_expires_at = nil
    self.remember_token            = nil
    save(validate: false)
  end

  def previous_login_date
    return @previous_login_date if @previous_login_date
    if (list = logins.limit(2).all).size != 2
      return nil
    end
    @previous_login_date = list[1].login_at  
  end

  private

  def password_required?
    password.blank?
  end

  def save_group
    exists = (group_rels.size > 0)

    group_rels.each_with_index do |rel, idx|
      if idx == 0 && in_group_id.present?
        if rel.group_id != in_group_id
          rel.class.where(user_id: rel.user_id, group_id: rel.group_id).update_all(group_id: in_group_id)
          rel.group_id = in_group_id
        end
      else
        rel.destroy
      end
    end

    if !exists && in_group_id.present?
      rel = Sys::UsersGroup.create(
        user_id:  id,
        group_id: in_group_id
      )
    end

    return true
  end
end
