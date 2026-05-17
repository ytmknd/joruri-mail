class System::Database < ApplicationRecord
  self.abstract_class = true
  db_configs = ActiveRecord::Base.configurations
  has_dev_jgw_core_config =
    if db_configs.respond_to?(:configs_for)
      db_configs.configs_for(env_name: 'dev_jgw_core').any?
    else
      db_configs.key?('dev_jgw_core')
    end
  establish_connection :dev_jgw_core if has_dev_jgw_core_config
end
