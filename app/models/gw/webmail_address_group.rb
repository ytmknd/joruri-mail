class Gw::WebmailAddressGroup < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Tree
  include Sys::Model::Auth::Free

  has_many :children, -> { order(:name, :id) },
    foreign_key: :parent_id, class_name: 'Gw::WebmailAddressGroup', dependent: :destroy

  has_many :groupings, foreign_key: :group_id, class_name: 'Gw::WebmailAddressGrouping', dependent: :destroy
  has_many :addresses, -> { order(:email, :id) }, through: :groupings

  attr_accessor :call_update_child_level_no
  after_save :update_child_level_no

  validates :user_id, :name, presence: true

  scope :readable, ->(user = Core.user) { where(user_id: user.id) }

  def self.user_root_groups(conditions = {})
    cond = conditions.merge(parent_id: 0, level_no: 1)
    self.user_groups(cond)
  end

  def self.user_groups(conditions = {})
    self.where(conditions.merge(user_id: Core.user.id)).order(:name, :id)
  end

  def self.user_sorted_groups(conditions = {})
    self.new.sorted_groups(self.user_root_groups(conditions))
  end

  def editable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def deletable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
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

  def nested_name
    nested_count = [0, level_no - 1].max
    "#{'　　'*nested_count}#{name}"
  end

  def parent_options
    self.class.user_root_groups.where.not(id: id)
      .map { |g| g.descendants { |rel| rel.where.not(id: id) } }.flatten
      .map { |g| [g.nested_name, g.id] }
  end

  def update_child_level_no
    if call_update_child_level_no && level_no_changed?
      children.each do |c|
        c.level_no = level_no + 1
        c.call_update_child_level_no = true
        c.save(validate: false)
      end
    end
  end
end
