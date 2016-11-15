module Sys::Model::Tree
  extend ActiveSupport::Concern

  included do
    belongs_to :parent, class_name: name
    has_many :children, class_name: name, foreign_key: :parent_id, dependent: :destroy
    scope :roots, -> { where(parent_id: [0, nil]) }
    scope :preload_children, -> {
      assocs = {}
      (1..3).inject(assocs) { |assoc, _| assoc[:children] = { children: {} } }
      preload(assocs)
    }
  end

  def ancestors(items = [])
    parent.ancestors(items) if parent
    items << self
  end

  def descendants(items = [], &block)
    items << self
    rel = children
    rel = yield(rel) || rel if block_given?
    rel.each {|c| c.descendants(items, &block) }
    items
  end

  def ancestors_and_children
    (ancestors + children).uniq
  end

  def root?
    parent_id == nil || parent_id == 0
  end
end
