class Webmail::Admin::AddressSelectorController < Webmail::Controller::Admin::Base

  def parse_address
    @addresses = {
      to: Email.parse_list(params[:to]),
      cc: Email.parse_list(params[:cc]),
      bcc: Email.parse_list(params[:bcc])
    }

    @addresses.each do |_, addrs|
      addrs.each do |addr|
        if addr.display_name
          name = addr.display_name
          name = '"' + name + '"' if name !~ /\"(.+)"$/
          addr.display_name = Email.unquote(name)
        end
      end
    end
  end
end
