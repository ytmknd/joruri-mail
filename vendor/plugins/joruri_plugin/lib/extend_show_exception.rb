# encoding: utf-8
module ActionDispatch
  class ShowExceptions
  private
    def render_exception(env, exception)
      log_error(exception)

      case exception
      when Mysql::ServerError::ConCountError
        if exception.message == "Too many connections"
          return rescue_action_originally(exception, 'データベースサーバーへの接続に失敗しました。しばらく時間をおいてからアクセスしてください。')
        end
      when RuntimeError
        if exception.message == "command out of sync"
          return rescue_action_originally(exception, 'データベースサーバーへの接続に失敗しました。しばらく時間をおいてからアクセスしてください。')
        end
      end
      
      request = Request.new(env)
      if @consider_all_requests_local || request.local?
        rescue_action_locally(request, exception)
      else
        rescue_action_in_public(exception)
      end
    rescue Exception => failsafe_error
      $stderr.puts "Error during failsafe response: #{failsafe_error}\n  #{failsafe_error.backtrace * "\n  "}"
      FAILSAFE_RESPONSE
    end
    
    def rescue_action_originally(exception, message)
      template = ActionView::Base.new(["#{Rails.root}/app/views"],
        :exception => exception,
        :message => message
      )
      body = template.render(:file => "gw/admin/error.html.erb", :layout => "layouts/base.html.erb")
      render(status_code(exception), body)
    end
  end
end