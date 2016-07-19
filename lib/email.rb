module Email
  class << self
    def parse(str, options = {})
      str = NKF.nkf('-WwM', str).gsub(/\n/, '')
      Mail::Address.new(str)
    rescue Mail::Field::ParseError => e
      if options[:raise_errors]
        raise e
      else
        nil
      end
    end

    def parse_list(str, options = {})
      str = str.split(/[\t\r\n]+/).join(', ')
      str = NKF.nkf('-WwM', str).gsub(/\n/, '')
      Mail::AddressList.new(str).addresses
    rescue Mail::Field::ParseError => e
      if options[:raise_errors]
        raise e
      else
        []
      end
    end

    def valid_email?(email)
      email =~ /\A[a-zA-Z0-9!#\$%&'\*\+\-\/=\?\^_`\{\|\}~\.]+@[a-zA-Z0-9\-\.]+\Z/ 
    end

    def quote_phrase(str)
      unquoted = Mail::Encodings.unquote(str)
      if unquoted =~ /[#{Regexp.escape(%Q|()<>[]:;@\\,."|)}[:cntrl:]]/
        Mail::Encodings.quote_phrase(unquoted)
      else
        unquoted
      end
    end

    def unquote(str)
      Mail::Encodings.unquote(str)
    end
  end
end
