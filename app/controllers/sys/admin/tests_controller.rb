class Sys::Admin::TestsController < Sys::Controller::Admin::Base
  layout 'base'

  def pre_dispatch
    return error_auth unless Core.user.has_auth?(:manager)
  end

  def timeout
    if params[:min]
      sleep params[:min].to_i*60
    elsif params[:sec]
      sleep params[:sec].to_i
    end
    render plain: 'OK'
  end
end
