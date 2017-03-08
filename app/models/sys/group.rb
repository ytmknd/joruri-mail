class Sys::Group < Sys::ManageDatabase
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Tree
  include Sys::Model::Auth::Manager

  belongs_to_active_hash :status, foreign_key: :state, class_name: 'Sys::Base::Status'
  belongs_to_active_hash :web_status, foreign_key: :web_state, class_name: 'Sys::Base::Status'

  belongs_to :parent, foreign_key: :parent_id, class_name: 'Sys::Group'
  has_many :children, -> { order(:sort_no, :code) }, 
    foreign_key: :parent_id, class_name: 'Sys::Group', dependent: :destroy
  has_many :enabled_children, -> { where(state: 'enabled').order(:sort_no, :code) },
    foreign_key: :parent_id, class_name: 'Sys::Group', dependent: :destroy

  has_many :users_groups, foreign_key: :group_id
  has_many :users, -> { order('sys_users.email, sys_users.account') },
    through: :users_groups, source: :user
  has_many :ldap_users, -> { where(ldap: 1, state: 'enabled').order('sys_users.email, sys_users.account') },
    through: :users_groups, source: :user
  has_many :enabled_users, -> { where(state: 'enabled').order('sys_users.email, sys_users.account') },
    through: :users_groups, source: :user

  attr_accessor :call_update_child_level_no
  after_save :update_child_level_no
  before_destroy :disable_users
  
  validates :state, :level_no, :name, :name_en, :ldap, presence: true
  validates :code, presence: true, uniqueness: true

  scope :enabled_roots, -> { where(parent_id: 1, state: 'enabled') }

  scope :enabled_children_counts, -> {
    joins(:enabled_children).group(:id).count('enabled_children_sys_groups.id')
  }
  scope :enabled_users_counts, -> {
    if self.show_only_ldap_user
      joins(:ldap_users).group(:id).count('sys_users.id')
    else
      joins(:enabled_users).group(:id).count('sys_users.id')
    end
  }

  def ou_name
    "#{code}#{name}"
  end

  def full_name
    ancestors.drop(1).map(&:name).join('　')
  end

  def nested_name
    nested_count = [0, level_no - 1].max
    "#{'　　'*nested_count}#{name}"
  end

  def self.show_only_ldap_user
    Joruri.config.application['webmail.show_only_ldap_user'] == 1
  end

  def users_having_email
    if self.class.show_only_ldap_user
      ldap_users.with_valid_email
    else
      enabled_users.with_valid_email
    end
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

  def ancestors_and_children_without_root_options
    ancestors_and_children[1..-1].map { |g| [g.nested_name.sub(/　　/, ''), g.id] }
  end

  private

  def disable_users
    users.each do |user|
      if user.groups.size == 1
        u = Sys::User.find_by(id: user.id)
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
        c.save(validate: false)
      end
    end
  end

  class << self
    def select_options
      self.roots.select(:id, :name, :level_no)
        .map {|g| g.descendants {|rel| rel.select(:id, :name, :level_no) } }
        .flatten.map {|g| [g.nested_name, g.id] }
    end

    def select_options_except(group)
      self.roots.select(:id, :name, :level_no)
        .map {|g| g.descendants {|rel| rel.select(:id, :name, :level_no).where.not(id: group.id) } }
        .flatten.map {|g| [g.nested_name, g.id] }
    end
  end
end
