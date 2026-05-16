class System::Database < ApplicationRecord
  self.abstract_class = true
  establish_connection :dev_jgw_core if ActiveRecord::Base.configurations.key?('dev_jgw_core')
end
