class Sys::Maintenance < ActiveRecord::Base
  include Sys::Model::Base
  include Sys::Model::Base::Page
  include Sys::Model::Auth::Manager

  belongs_to_active_hash :status, foreign_key: :state, class_name: 'Sys::Base::Status'

  validates :state, :title, :body, :published_at, presence: true

  class << self
    def latest_maintenance
      self.state_public.order(published_at: :desc).first
    end
  end
end
