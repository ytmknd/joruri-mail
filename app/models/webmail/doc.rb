class Webmail::Doc < ApplicationRecord
  include Sys::Model::Base
  include Sys::Model::Auth::Manager

  belongs_to_active_hash :status, foreign_key: :state, class_name: 'Sys::Base::Status'

  validates :state, :published_at, :title, :body, presence: true

  scope :state_public, -> { where(state: 'public').where(arel_table[:published_at].lt(Time.now)) }

  def readable?
    true
  end

  def states
    [['公開','public'],['非公開','closed']]
  end
end
