class ApplicationController < ActionController::Base
  include Jpmobile::ViewSelector
  include ParamsKeeper
  protect_from_forgery #:secret => '1f0d667235154ecf25eaf90055d99e99'
  before_action :initialize_application
  after_action :inline_css_for_mobile
  after_action :set_content_type_for_mobile
  rescue_from Exception, with: :rescue_exception
  trans_sid

  def initialize_application
    return false if Core.dispatched?
    return Core.dispatched
  end

  def response_html?
    response.content_type =~ Regexp.union(%r|text/html|, %r|application/xhtml\+xml|)
  end

  def inline_css_for_mobile
    if request.mobile? && response_html?
      css_files = Nokogiri::HTML(response.body).xpath('//head/link[@rel="stylesheet"]/@href')
        .map {|href| Rails.root.join("public/#{href}").to_s }
      begin
        pm = Premailer.new(response.body,
          with_html_string: true,
          preserve_styles: true,
          input_encoding: 'utf-8',
          adapter: :hpricot,
          css: css_files
        )
        response.body = pm.to_inline_css.sub(/charset=UTF-8/i, "charset=#{request.mobile.default_charset}")
      rescue => e
        error_log(e)
      end
    end
  end

  def set_content_type_for_mobile
    if request.mobile? && response_html?
      case request.mobile
      when Jpmobile::Mobile::Docomo
        if request.mobile.imode_browser_version == '1.0'
          response.headers["Content-Type"] = "application/xhtml+xml; charset=#{request.mobile.default_charset}"
        end
      end
    end
  end

  def send_data(data, options = {})
    if options[:filename].present?
      options[:filename].gsub!(/[\/\<\>\|:"\?\*\\]/, '_')
      case
      when request.env['HTTP_USER_AGENT'] =~ /(MSIE 6|MSIE 7)/
        options[:filename] = NKF.nkf("-s", options[:filename])
        options[:filename] = options[:filename].chars.map{|c| c.unpack("C*").last == 92 ? URI::escape(NKF.nkf("-w", c)) : c.to_s}.join
      when request.env['HTTP_USER_AGENT'] =~ /(MSIE|Trident)/
        options[:filename] = URI::escape(options[:filename])
      end
    end
    super(data, options)
  end

  private

  def rescue_exception(exception)
    @exception = exception
    error_log("#{@exception}\n" + @exception.backtrace.join("\n")) if Rails.env == 'production'
    render template: 'application/exception', layout: true, status: 500
  end

  def http_error(status, message = nil)
    if status != 404
      error_log("#{status} #{request.fullpath} #{message.to_s.gsub(/\n/, ' ')}")
    end

    file =
      if FileTest.exist?("#{Rails.public_path}/#{status}.html")
        "#{Rails.public_path}/#{status}.html"
      else
        "#{Rails.public_path}/500.html"
      end

    @message = message
    return respond_to do |format|
      format.html { render file: file, layout: false, status: status }
      format.xml  { render xml: "<errors><error>#{status} #{message}</error></errors>" }
    end
  end
end
