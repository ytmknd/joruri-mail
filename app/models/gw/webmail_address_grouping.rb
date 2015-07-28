class Gw::WebmailAddressGrouping < ActiveRecord::Base
  include Sys::Model::Base

  belongs_to :group, :foreign_key => :group_id, :class_name => 'Gw::WebmailAddressGroup'
  belongs_to :address, :foreign_key => :address_id, :class_name => 'Gw::WebmailAddress'
end