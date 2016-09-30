class Sys::Sequence < ApplicationRecord
  scope :versioned, ->(v) { where(version: v) }
end
