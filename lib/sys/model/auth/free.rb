module Sys::Model::Auth::Free
  extend ActiveSupport::Concern

  def creatable?
    true
  end

  def readable?
    true
  end

  def editable?
    true
  end

  def deletable?
    true
  end
end
