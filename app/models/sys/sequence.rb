class Sys::Sequence < ActiveRecord::Base
  scope :versioned, ->(v) { where(version: v) }
end
