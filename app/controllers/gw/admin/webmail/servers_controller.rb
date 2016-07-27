class Gw::Admin::Webmail::ServersController < Gw::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def status
    if protect_against_forgery? && params[:authenticity_token] != form_authenticity_param
      status = 'NG TokenError'
    else
      ret = Gw::Webmail::ServerChecker.check_status
      status = ret[:imap] && ret[:smtp] ? 'OK' : 'NG'
    end
    render json: { status: status }
  end
end
