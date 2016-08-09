class Webmail::AddressGrouping < ActiveRecord::Base
  include Sys::Model::Base

  belongs_to :group, foreign_key: :group_id, class_name: 'Webmail::AddressGroup'
  belongs_to :address, foreign_key: :address_id, class_name: 'Webmail::Address'
end
