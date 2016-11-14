class Webmail::Admin::ServersController < Webmail::Controller::Admin::Base
  include Sys::Controller::Scaffold::Base

  def status
    status =
      if protect_against_forgery? && params[:authenticity_token] != form_authenticity_param
        'NG TokenError'
      else
        if Joruri.config.application['webmail.check_servers_before_send'] == 2
          ret = Webmail::Lib::Server.check_status
          ret[:imap] && ret[:smtp] ? 'OK' : 'NG'
        else
          'OK'
        end
      end
    render json: { status: status }
  end
end
