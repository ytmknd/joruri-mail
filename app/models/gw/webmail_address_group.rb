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
  scope :user_root_groups, -> { where(parent_id: 0, level_no: 1, user_id: Core.user.id) }
  scope :preload_children, ->(depth = 3) {
    (depth -= 1) <= 0 ? all : preload(children: :children).preload_children(depth)
  }

  scope :children_counts, -> {
    joins(:children).group(:id).count('children_gw_webmail_address_groups.id')
  }
  scope :addresses_counts, -> {
    joins(:addresses).group(:id).count('gw_webmail_addresses.id')
  }

  def editable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
  end

  def deletable?
    Core.user.has_auth?(:manager) || user_id == Core.user.id
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

  def descendant_options
    descendants {|rel| rel.select(:id, :name, :level_no) }.map {|g| [g.nested_name, g.id] }
  end

  private

  def update_child_level_no
    if call_update_child_level_no && level_no_changed?
      children.each do |c|
        c.level_no = level_no + 1
        c.call_update_child_level_no = true
        c.save(validate: false)
      end
    end
  end

  class << self
    def user_sorted_groups
      user_root_groups.map { |g| g.descendants { |rel| rel.order(:name, :id) } }.flatten
    end
  end
end
