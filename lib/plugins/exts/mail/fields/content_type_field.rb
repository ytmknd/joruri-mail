module Mail
  module ContentTypeFieldFix
    def parameters
      super
      @parameters.delete("charset") if @parameters.key?("boundary") || @parameters.key?("name")
      @parameters
    end
  end
  class ContentTypeField
    prepend ContentTypeFieldFix
  end
end
