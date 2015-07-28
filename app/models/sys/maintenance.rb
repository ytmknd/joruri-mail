class Sys::Maintenance < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Base::Page
  include Sys::Model::Rel::Unid
  include Sys::Model::Rel::Creator
  include Sys::Model::Auth::Manager
  
  belongs_to :status,  :foreign_key => :state, :class_name => 'Sys::Base::Status'
  
#  validate do |m|
#    if published_at.blank?
#      errors.add :in_published_at, :blank
#    end
#  end

  #validates_presence_of :state, :published_at, :title, :body
  validates_presence_of :state, :title, :body, :published_at
    
#  attr_accessor :in_published_at
    
end
