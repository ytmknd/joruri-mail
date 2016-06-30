class ApplicationController < ActionController::Base
  include Jpmobile::ViewSelector
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

  def skip_layout
    self.class.layout 'base'
  end

  def query(params = nil)
    Util::Http::QueryString.get_query(params)
  end

  def send_mail(mail_fr, mail_to, subject, message)
    return false if mail_fr.blank?
    return false if mail_to.blank?
    Sys::Lib::Mail::Base.deliver_default(mail_fr, mail_to, subject, message)
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
    Core.terminate

    log  = exception.to_s
    log += "\n" + exception.backtrace.join("\n") if Rails.env.to_s == 'production'
    error_log(log)

    html  = %Q(<div style="padding: 15px 20px; color: #e00; font-weight: bold; line-height: 1.8;">)
    case
    when exception.is_a?(Sys::Lib::Net::Imap::Error)
      html += %Q(#{exception})
    else
      html += %Q(エラーが発生しました。<br />#{exception} &lt;#{exception.class}&gt;)
    end
    html += %Q(</div>)
    if Rails.env.to_s != 'production'
      html += %Q(<div style="padding: 15px 20px; border-top: 1px solid #ccc; color: #800; line-height: 1.4;">)
      html += exception.backtrace.join("<br />")
      html += %Q(</div>)
    end
    render inline: html, layout: true, status: 500
  end

  def rescue_action(error)
    case error
    when ActionController::InvalidAuthenticityToken
      http_error(422, error.to_s)
    else
      Core.terminate
      super
    end
  end

  ## Production && local
  def rescue_action_in_public(exception)
    #exception.each{}
    http_error(500, nil)
  end

  def http_error(status, message = nil)
    Core.terminate
    
###    Page.error = status
    
    ## errors.log
    if status != 404
      error_log("#{status} #{request.fullpath} #{message.to_s.gsub(/\n/, ' ')}")
    end

    ## Render
    file = "#{Rails.public_path}/500.html"
###    if Page.site && FileTest.exist?("#{Page.site.public_path}/#{status}.html")
###      file = "#{Page.site.public_path}/#{status}.html"
###    elsif Core.site && FileTest.exist?("#{Core.site.public_path}/#{status}.html")
###      file = "#{Core.site.public_path}/#{status}.html"
###    els
    if FileTest.exist?("#{Rails.public_path}/#{status}.html")
      file = "#{Rails.public_path}/#{status}.html"
    end

    @message = message
    return respond_to do |format|
      #render :text => "<html><body><h1>#{message}</h1></body></html>"
      format.html { render(:status => status, :file => file, :layout => false) }
      format.xml  { render :xml => "<errors><error>#{status} #{message}</error></errors>" }
    end
  end
end
