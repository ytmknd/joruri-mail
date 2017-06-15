class ExceptionController < ApplicationController
  protect_from_forgery except: [:index]

  def index
    if request.get?
      http_error 404
    else
      head :method_not_allowed
    end
  end
end
