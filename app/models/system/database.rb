class System::Database < ActiveRecord::Base
  self.abstract_class = true
  establish_connection :dev_jgw_core rescue nil
end
