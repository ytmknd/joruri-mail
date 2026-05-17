module Mail
  module AddressFix
    def initialize(value = nil)
      ret = super
      # patch start: unquote 'word \"word\" word'
      if @data && @data.display_name && @data.display_name !~ /\A"(.+)"\z/
        @data.display_name = Utilities.unquote('"' + @data.display_name + '"')
      end
      # patch end
      ret
    end
  end
  class Address
    prepend AddressFix
  end
end
