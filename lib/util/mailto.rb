class Util::Mailto
  class << self
    def parse(url)
      parsed = {}
      uri = URI.parse(URI.escape(NKF::nkf('-w', url)))
      if uri.scheme == 'mailto'
        parsed[:to] = URI.unescape(uri.to)
        uri.headers.each do |header|
          parsed[header[0].to_sym] = URI.unescape(header[1]) if header.size == 2
        end
      end
      parsed
    rescue URI::InvalidURIError => e
      {}
    end
  end
end
