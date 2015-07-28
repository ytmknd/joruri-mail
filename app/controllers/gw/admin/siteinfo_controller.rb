# coding: utf-8
class Gw::Admin::SiteinfoController < Gw::Controller::Admin::Base
  #layout "admin/gw/webmail/siteinfo"
  layout "admin/gw"
  
  def index
    
    if Core.full_uri && (data = Core.full_uri.match(/^[a-z]+:\/\/([^\/]+)\//))
      @host = data[1]
    else
      @host = nil
    end
    
    #クライアントIPアドレス
    if http_client_ip = request.env['HTTP_CLIENT_IP']
      @remote_ip = http_client_ip 
    elsif x_forward_for = request.env['HTTP_X_FORWARD_FOR']
      @remote_ip = x_forward_for.split(',').last.strip
    else
      @remote_ip = request.remote_ip
    end
  end
  
end