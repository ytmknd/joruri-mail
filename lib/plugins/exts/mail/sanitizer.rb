module Mail
  class Sanitizer
    def self.adjust_semicolon(value)
      # sanitize 'name="test.txt";;'
      value = value.gsub(/;+$/, '')
    end

    def self.adjust_encoding(value)
      value.gsub(/(name|filename)\s*=\s*"([^"]+?)"\s*(;|$)/im) do |match|
        # sanitize 'name="添付ファイル名.txt"' (name is not encoded)
        param = $1
        filename = $2
        delim = $3
        #charset = NKF.guess(filename).to_s.downcase
        charset = CharlockHolmes::EncodingDetector.detect(filename)[:encoding].downcase

        if filename !~ /\=\?(.+)?\?[BQ]\?(.*)\?\=/im && !charset.in?(['iso-8859-1', 'us-ascii', 'ascii-8bit'])
          encoded, encoding = RubyVer.b_value_encode(filename.force_encoding(charset))
          encoded = encoded.gsub(/[\r\n]/, '')
          %Q|#{param}="=?#{charset.upcase}?B?#{encoded}?="#{delim}|
        else
          match
        end
      end
    end

    def self.adjust_quotation(value)
      value = value.gsub(/(name|filename[\d*]*)\s*=\s*"+([^"]+?)"+(;|$)/im) do
        # sanitize 'name=""test.txt"', 'name="test.txt""'
        %Q|#{$1}="#{$2}"#{$3}|
      end
      value = value.gsub(/(name|filename[\d*]*)\s*=\s*([^"]+?)\s*(;|$)/im) do
        # sanitize 'name=test.txt'
        %Q|#{$1}="#{$2}"#{$3}|
      end
      value
    end

    def self.adjust_mime_type(value)
      case
      when value =~ /^\s*name=(.*)$/im
        # sanitize 'name="test.txt"'
        "application/octet-stream; name=#{$1}"
      when value =~ /^\s*;\s*(.*)$/mi
        # sanitize ' ; name="test.txt"'
        "application/octet-stream; #{$1}"
      when value =~ /^\s*([^\/]+?);\s*(.*)$/mi
        # sanitize 'unknown; name="test.txt"'
        "#{$1}/unknown; #{$2}"
      else
        value
      end
    end

    def self.adjust_invalid_content_transfer_encoding(value)
      value.gsub(/\s*Content-Transfer-Encoding: 8bit\s*(;|$)/m, '')
    end
  end
end
