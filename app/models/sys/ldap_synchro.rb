class Sys::LdapSynchro < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Base::Config
  include Sys::Model::Tree
  include Sys::Model::Auth::Manager

  validates :version, :entry_type, :code, :name, presence: true

  has_many :children, -> { where(entry_type: 'group').order(:sort_no, :code) },
    class_name: self.name, foreign_key: :parent_id
  has_many :users, -> { where(entry_type: 'user').order(:sort_no, :code) },
    class_name: self.name, foreign_key: :parent_id

  scope :preload_children_and_users, -> {
    assocs = { users: nil }
    (1..3).inject(assocs) { |assoc, _| assoc[:children] = { users: nil, children: {} } }
    preload(assocs)
  }
end
