class Sys::Model::ActiveModel
  include ActiveModel::Model

  class << self
    def i18n_scope
      :activerecord
    end
  end
end
