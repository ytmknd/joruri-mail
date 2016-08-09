module Sys::Model::Base::Config
  extend ActiveSupport::Concern

  included do
    scope :state_enabled, -> { where(state: 'enabled') }
    scope :state_disabled, -> { where(state: 'disabled') }
  end

  def states
    [['有効','enabled'],['無効','disabled']]
  end

  def enabled?
    state == 'enabled'
  end

  def disabled?
    state == 'disabled'
  end
end
