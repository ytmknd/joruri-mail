module ContentRefresher
  extend ActiveSupport::Concern

  included do
    before_action :enable_content_refresh, if: -> { params[:content_refresh] }
    after_action :extract_content_body, if: -> { @content_refresh_enabled }
  end

  private

  def enable_content_refresh
    params.delete(:content_refresh)
    @content_refresh_enabled = true
  end

  def extract_content_body
    body = Nokogiri::HTML(response.body).xpath('//*[@id="contentBody"]').inner_html
    self.response_body = body
  end

  def rescue_exception(e)
    super
    extract_content_body if @content_refresh_enabled
  end
end
