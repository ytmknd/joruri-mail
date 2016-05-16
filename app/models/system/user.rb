class System::User < System::Database
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Auth::Manager

  has_many :users_groups, foreign_key: :user_id, class_name: 'System::UsersGroup'
  has_many :groups, through: :users_groups, source: :user

  validates :mobile_password, length: { minimum: 4, if: lambda { |u| u.mobile_password && u.mobile_password.length != 0 } }
end
