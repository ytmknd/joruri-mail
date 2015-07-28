# encoding: utf-8
class Gw::WebmailAddressGroup < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Tree
  include Sys::Model::Auth::Free
  
  has_many :children, :foreign_key => :parent_id, :class_name => 'Gw::WebmailAddressGroup',
    :order => 'name, id', :dependent => :destroy
  
  has_many :groupings, :foreign_key => :group_id, :class_name => 'Gw::WebmailAddressGrouping',
    :dependent => :destroy
  has_many :addresses, :through => :groupings, :order => 'email, id'
  
  #has_many :addresses, :foreign_key => :group_id, :class_name => 'Gw::WebmailAddress',
  #  :order => 'email, id', :dependent => :destroy
  
  attr_accessor :call_update_child_level_no
  after_save :update_child_level_no
  
  validates_presence_of :user_id, :name
    
  def self.user_root_groups(conditions = {})
    cond = conditions.merge({:parent_id => 0, :level_no => 1})
    self.user_groups(cond)
  end

  def self.user_groups(conditions = {})
    cond = conditions.merge({:user_id => Core.user.id})
    self.find(:all, :conditions => cond, :order => 'name, id')
  end
  
  def self.user_sorted_groups(conditions = {})
    self.new.sorted_groups(self.user_root_groups(conditions))
  end
  
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
  
  def candidate_parents
    choices = []
    sorted_groups(self.class.user_root_groups).each do |g|
      choices << [('&nbsp;' * (g.level_no - 1) * 4 + CGI.escapeHTML(g.name)).html_safe, g.id]
    end
    return choices  
  end
 
  def parents_tree_names
    return @parents_tree_names if @parents_tree_names
    @parents_tree_names = self.parents_tree.collect {|g| g.name }
  end

  def sorted_groups(roots)
    groups = []
    down = lambda do |p|
      if new_record? || p.id != id
        groups << p
        p.children.each {|child| down.call(child)}
      end
    end
    roots.each {|item| down.call(item)}
    return groups
  end
  
  def update_child_level_no
    if call_update_child_level_no && level_no_changed?
      children.each do |c|
        c.level_no = level_no + 1
        c.call_update_child_level_no = true
        c.save(:validate => false)
      end
    end
  end
end
