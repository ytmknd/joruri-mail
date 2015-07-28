# encoding: utf-8
class Gw::WebmailDoc < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Base::Page
  include Sys::Model::Auth::Manager

  belongs_to :status, :foreign_key => :state, :class_name => 'Sys::Base::Status'
  
  validates_presence_of :state, :published_at, :title, :body
  
  def public
    self.and :state, 'public'
    self.and :published_at, '<', Time.now
    self
  end
  
  def readable?
    return self
  end
end
