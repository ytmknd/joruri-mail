module Mail
  module ContentDispositionFieldFix
    def filename
      # supprt for RFC2231 filename
      if parameters.any? { |k, _| k =~ /^filename\*/ }
        filename = parameters.select { |k, _| k =~ /^filename\*/ }.values.join
        if match = filename.match(/([^']+)'([^']*?)'(.+)/)
          @filename = Mail::RubyVer.transcode_charset(CGI.unescape(match[3]), match[1])
        else
          @filename = filename
        end
      else
        super
      end
    end
  end
  class ContentDispositionField < StructuredField
    prepend ContentDispositionFieldFix
  end
end
