module Sys::Model::Base
  extend ActiveSupport::Concern

  included do
    self.table_name = self.name.underscore.gsub('/', '_').downcase.pluralize
  end

  class_methods do
    def escape_like(s)
      s.gsub(/[\\%_]/) {|r| "\\#{r}"}
    end
  end
end
