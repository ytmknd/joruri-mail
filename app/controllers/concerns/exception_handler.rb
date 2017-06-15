module ExceptionHandler
  extend ActiveSupport::Concern

  included do
    rescue_from Exception, with: :rescue_exception
  end

  private

  def rescue_exception(e)
    error_log "#{e}\n#{e.backtrace.join("\n")}"

    if !params.key?(:format) || params[:format] == 'html'
      @exception = e
      response.status = 500
      self.response_body = render_to_string(template: 'application/exception', layout: true)
    else
      raise e
    end
  end
end
