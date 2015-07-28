# encoding: utf-8

# mobile_filter
Rails.application.config.jpmobile.mobile_filter
Rails.application.config.jpmobile.form_accept_charset_conversion = true

module Jpmobile
  module RequestWithMobile
    def mobile?
      mobile
    end
  end
end

module Jpmobile::Mobile
  class AbstractMobile
    def variants
      return @_variants if @_variants

      @_variants = self.class.ancestors.select {|c| c.to_s =~ /^Jpmobile/ && c.to_s !~ /Emoticon/}.map do |klass|
        klass = klass.to_s.
          gsub(/Jpmobile::/, '').
          gsub(/AbstractMobile::/, '').
          gsub(/Mobile::SmartPhone/, 'smart_phone').
          gsub(/Mobile::Tablet/, 'tablet').
          gsub(/::/, '_').
          gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2').
          gsub(/([a-z\d])([A-Z])/, '\1_\2').
          downcase
        klass =~ /abstract/ ? "mobile" : klass
      end

      if @_variants.include?('tablet')
        @_variants = @_variants.reject{|v| v == "mobile"}.map{|v| v.gsub(/mobile_/, "tablet_")}
      elsif @_variants.include?("smart_phone")
        @_variants = @_variants.reject{|v| v == "mobile"}.map{|v| v.gsub(/mobile_/, "smart_phone_")}
        @_variants << 'mobile'
      end

      @_variants
    end
  end
end

module Jpmobile::Mobile
  class Docomo < AbstractMobile
    def default_charset
      "UTF-8"
    end
    def to_internal(str)
      str
    end
    def to_external(str, content_type, charset)
      [str, charset]
    end
    def supports_cookie?
      imode_browser_version != '1.0' && imode_browser_version !~ /^2.0/
    end
  end
end

module Jpmobile
  module Util
    module_function
    def sjis(str)
      if str.respond_to?(:force_encoding) and !shift_jis?(str)
        str = NKF.nkf('-s -x --oc=CP932', str)
        str.force_encoding(SJIS)
      end
      str
    end
    def utf8(str)
      if str.respond_to?(:force_encoding) and !utf8?(str)
        str = NKF.nkf('-w', str)
        str.force_encoding(UTF8)
      end
      str
    end
    def jis(str)
      if str.respond_to?(:force_encoding) and !jis?(str)
        str = NKF.nkf('-j', str)
        str.force_encoding(JIS)
      end
      str
    end
    def utf8_to_sjis(utf8_str)
      # 波ダッシュ対策
      utf8_str = wavedash_to_fullwidth_tilde(utf8_str)
      NKF.nkf("-m0 -x -W --oc=cp932", utf8_str).gsub(/\n/, "\r\n")
    end
    def sjis_to_utf8(sjis_str)
      utf8_str = NKF.nkf("-m0 -x -w --ic=cp932", sjis_str).gsub(/\r\n/, "\n")
      # 波ダッシュ対策
      fullwidth_tilde_to_wavedash(utf8_str)
    end
    def utf8_to_jis(utf8_str)
      NKF.nkf("-m0 -x -Wj", utf8_str).gsub(/\n/, "\r\n")
    end
    def jis_to_utf8(jis_str)
      NKF.nkf("-m0 -x -Jw", jis_str).gsub(/\r\n/, "\n")
    end
  end
end

case Joruri.config.application['sys.force_site']
when 'mobile'
  module Jpmobile::Mobile
    class Others < SmartPhone
      USER_AGENT_REGEXP = /./
    end
  end
  
  module Jpmobile::Mobile
    @carriers << 'Others'
  end
when 'pc'
  module Jpmobile::Mobile
    @carriers = []
  end
end