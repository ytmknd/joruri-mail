class Webmail::Admin::SiteinfoController < Webmail::Controller::Admin::Base
  layout 'admin/webmail'

  def index
    if Core.full_uri && (data = Core.full_uri.match(/^[a-z]+:\/\/([^\/]+)\//))
      @host = data[1]
    else
      @host = nil
    end

    if http_client_ip = request.env['HTTP_CLIENT_IP']
      @remote_ip = http_client_ip 
    elsif x_forward_for = request.env['HTTP_X_FORWARD_FOR']
      @remote_ip = x_forward_for.split(',').last.strip
    else
      @remote_ip = request.remote_ip
    end
  end
end
