# encoding: utf-8
class Gw::WebmailMailAddressHistory < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Tree
  include Sys::Model::Auth::Free
  
  attr_accessor :display_name
  
end