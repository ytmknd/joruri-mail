class Webmail::Util::Server
  class << self
    def check_status
      { imap: check_imap_status, smtp: check_smtp_status }
    end

    private

    def check_imap_status
      imap_settings = Joruri.config.imap_settings
      begin
        imap_sock = Timeout.timeout(10) do
          TCPSocket.open(imap_settings[:address], imap_settings[:port])
        end
        true
      rescue => e
        false
      ensure
        imap_sock.close if imap_sock
      end
    end

    def check_smtp_status
      smtp_settings = ActionMailer::Base.smtp_settings
      begin
        smtp_sock = Timeout.timeout(10) do
          TCPSocket.open(smtp_settings[:address], smtp_settings[:port])
        end
        true
      rescue => e
        false
      ensure
        smtp_sock.close if smtp_sock
      end
    end
  end
end
