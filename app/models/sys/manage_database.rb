class Sys::ManageDatabase < ApplicationRecord
  self.abstract_class = true
  establish_connection :joruri_manage rescue nil
end
