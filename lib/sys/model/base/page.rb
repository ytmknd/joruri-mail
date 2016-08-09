module Sys::Model::Base::Page
  extend ActiveSupport::Concern

  included do
    scope :state_public, -> { where(state: 'public') }
  end

  def states
    [['公開','public'],['非公開','closed']]
  end

  def public?
    state == 'public' && published_at
  end
end
