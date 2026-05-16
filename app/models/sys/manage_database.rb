class Sys::ManageDatabase < ApplicationRecord
  self.abstract_class = true
  establish_connection :joruri_manage if ActiveRecord::Base.configurations.key?('joruri_manage')
end
