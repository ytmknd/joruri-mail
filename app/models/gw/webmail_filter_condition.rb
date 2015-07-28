# encoding: utf-8
class Gw::WebmailFilterCondition < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Auth::Free

  belongs_to :filter, :foreign_key => :filter_id, :class_name => 'Gw::WebmailFilter'
  
  attr_accessor :columns, :inclusions, :values
  
  validates_presence_of :user_id, :column, :value
  
  def readable
    self.and :user_id, Core.user.id
    self
  end
  
  def editable?
    return true if Core.user.has_auth?(:manager)
    user_id == Core.user.id
  end
  
  def deletable?
    return true if Core.user.has_auth?(:manager)
    user_id == Core.user.id
  end
  
  def column_label
    filter.condition_column_labels.each {|c| return c[0] if column == c[1].to_s }
    nil
  end
  
  def inclusion_label
    filter.condition_inclusion_labels.each {|c| return c[0] if inclusion == c[1].to_s }
    nil
  end
end
