class System::Database < ApplicationRecord
  self.abstract_class = true
  establish_connection :dev_jgw_core rescue nil
end
