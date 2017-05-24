class ExceptionController < ApplicationController
  protect_from_forgery except: [:index]

  def index
    case request.method
    when 'OPTIONS'
      head :method_not_allowed
    else
      http_error 404
    end
  end
end
