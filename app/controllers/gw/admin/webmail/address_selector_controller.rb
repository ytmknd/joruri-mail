# encoding: utf-8
class Gw::Admin::Webmail::AddressSelectorController < Gw::Controller::Admin::Base

  def parse_address
    mail = Gw::WebmailMail.new
    mail.charset = 'utf-8'
    @addresses = {}
    @addresses[:to] = extract_addresses(mail.parse_address(params[:to]))
    @addresses[:cc] = extract_addresses(mail.parse_address(params[:cc]))
    @addresses[:bcc] = extract_addresses(mail.parse_address(params[:bcc]))
  end

protected

  def extract_addresses(addrs)
    rtn = []
    addrs.each do |addr|
      begin
        rtn << {
          :name => addr.display_name,
          :email => addr.address
        }
      rescue
        #例外発生時は無視
      end
    end
    rtn
  end
end