class Webmail::Admin::ServersController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def status
    if protect_against_forgery? && params[:authenticity_token] != form_authenticity_param
      status = 'NG TokenError'
    else
      ret = Webmail::Util::Server.check_status
      status = ret[:imap] && ret[:smtp] ? 'OK' : 'NG'
    end
    render json: { status: status }
  end
end
