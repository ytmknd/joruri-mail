class System::UsersGroup < System::Database
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Auth::Manager

  belongs_to :user, foreign_key: :user_id, class_name: 'System::User'
  belongs_to :group, foreign_key: :group_id, class_name: 'System::Group'
end
