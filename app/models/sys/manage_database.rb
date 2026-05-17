class Sys::ManageDatabase < ApplicationRecord
  self.abstract_class = true
  db_configs = ActiveRecord::Base.configurations
  has_manage_config =
    if db_configs.respond_to?(:configs_for)
      db_configs.configs_for(env_name: 'joruri_manage').any?
    else
      db_configs.key?('joruri_manage')
    end
  establish_connection :joruri_manage if has_manage_config
end
