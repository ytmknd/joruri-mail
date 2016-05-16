class System::Group < System::Database
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Auth::Manager
  
  has_many :children, -> { order(:sort_no) },
    foreign_key: :parent_id, class_name: 'System::Group'
  has_many :ldap_children, -> { where(ldap: 1, state: 'enabled').order(:sort_no) },
    foreign_key: :parent_id, class_name: 'System::Group'
  has_many :enabled_children, -> { where(state: 'enabled').order(:sort_no) },
    foreign_key: :parent_id, class_name: 'System::Group'
  
  has_many :users_groups, foreign_key: :group_id, class_name: 'System::UsersGroup'
  
  has_many :users, -> { order('system_users.email, system_users.code') },
    through: :users_groups, source: :user
  has_many :ldap_users, -> { where(ldap: 1, state: 'enabled').order('system_users.email, system_users.code') },
    through: :users_groups, source: :user
end
