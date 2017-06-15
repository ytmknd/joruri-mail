module Mail
  class Ruby19
    def Ruby19.transcode_charset(str, from_encoding, to_encoding = Encoding::UTF_8)
      # patch start
      case from_encoding.to_s.downcase
      when /^unicode-1-1-utf-7$/
        require 'net/imap'
        Net::IMAP.decode_utf7(str.gsub(/\+([\w\+\/]+)-/, '&\1-'))
      when /^iso-2022-jp/, /^shift[_-]jis$/, /^x[_-]sjis$/, /^euc-jp$/, /^cp932$/
        NKF::nkf('-wx --cp932', str).gsub(/\0/, "")
      else
        charset_encoder.encode(str.dup, from_encoding).encode(to_encoding, :undef => :replace, :invalid => :replace)
      end
      # patch end
    end
  end
end
