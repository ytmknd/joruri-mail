# encoding: utf-8
class Sys::Model::ActiveModel
  include ActiveModel::Validations
  include ActiveModel::Conversion

  def persisted? ; false ; end

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value) rescue nil
    end
  end
  
  class << self
    def i18n_scope
      :activerecord
    end
  end
end