module Sys::Model::ActiveModel
  extend ActiveSupport::Concern
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  class_methods do
    def i18n_scope
      :activerecord
    end
  end
end
