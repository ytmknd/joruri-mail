module Mail
  class Ruby19
    def Ruby19.transcode_charset(str, from_encoding, to_encoding = Encoding::UTF_8)
      # patch start
      case from_encoding.to_s.downcase
      when /^unicode-1-1-utf-7$/
        require 'net/imap'
        Net::IMAP.decode_utf7(str.gsub(/\+([\w\+\/]+)-/, '&\1-'))
      when /^utf-8$/, /^iso-2022-jp/, /^shift[_-]jis$/, /^x[_-]sjis$/, /^euc-jp$/, /^cp932$/
        NKF::nkf('-wx --cp932', str).gsub(/\0/, "")
      else
        charset_encoder.encode(str.dup, from_encoding).encode(to_encoding, :undef => :replace, :invalid => :replace)
      end
      # patch end
    end

    def Ruby19.b_value_decode(str)
      match = str.match(/\=\?(.+)?\?[Bb]\?(.*)\?\=/m)
      # patch start
      if match
        charset = match[1]
        str = Ruby19.decode_base64(match[2])
        decoded = transcode_charset(str, charset)
      else
        decoded = str.encode(Encoding::UTF_8, :invalid => :replace, :replace => "")
      end
      # patch end
      decoded.valid_encoding? ? decoded : decoded.encode(Encoding::UTF_16LE, :invalid => :replace, :replace => "").encode(Encoding::UTF_8)
    rescue Encoding::UndefinedConversionError, ArgumentError, Encoding::ConverterNotFoundError
      warn "Encoding conversion failed #{$!}"
      str.dup.force_encoding(Encoding::UTF_8)
    end

    def Ruby19.q_value_decode(str)
      match = str.match(/\=\?(.+)?\?[Qq]\?(.*)\?\=/m)
      # patch start
      if match
        charset = match[1]
        string = match[2].gsub(/_/, '=20')
        # Remove trailing = if it exists in a Q encoding
        string = string.sub(/\=$/, '')
        str = Encodings::QuotedPrintable.decode(string)
        str = transcode_charset(str, charset)
        # We assume that binary strings hold utf-8 directly to work around
        # jruby/jruby#829 which subtly changes String#encode semantics.
        decoded = str.encode(Encoding::UTF_8, :invalid => :replace, :replace => "")
      else
        decoded = str.encode(Encoding::UTF_8, :invalid => :replace, :replace => "")
      end
      # patch end
      decoded.valid_encoding? ? decoded : decoded.encode(Encoding::UTF_16LE, :invalid => :replace, :replace => "").encode(Encoding::UTF_8)
    rescue Encoding::UndefinedConversionError, ArgumentError, Encoding::ConverterNotFoundError
      warn "Encoding conversion failed #{$!}"
      str.dup.force_encoding(Encoding::UTF_8)
    end
  end
end
