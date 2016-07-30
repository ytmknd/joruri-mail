require 'net/imap'
module Sys::Lib::Net::Imap
  def self.connect
    unless config = Joruri.config.imap_settings
      raise NameError, "undefined setting `imap_settings` for #{self}"
    end

    imap = nil
    begin
      username = Core.current_user.account
      password = Core.current_user.password
      Timeout.timeout(3) do
        imap = Net::IMAP.new(config[:address], config[:port], config[:usessl])
        imap.login(username, password)
      end
      return imap
    rescue Net::IMAP::ByeResponseError => e
      raise "IMAP: 接続に失敗 (ByeResponseError)"
    rescue Net::IMAP::NoResponseError => e
      raise "IMAP: 認証に失敗しました。アカウントとパスワードの設定を確認してください。" if e.message == 'Authentication failed.'
      raise "IMAP: 接続に失敗 (NoResponseError)"
    rescue OpenSSL::SSL::SSLError
      raise "IMAP: 接続に失敗 (SSLError)"
    rescue Errno::ETIMEDOUT => e
      raise "IMAP: 接続に失敗 (ETIMEOUT)"
    rescue Errno::ECONNRESET
      raise "IMAP: 接続に失敗 (ECONNRESET)"
    rescue Timeout::Error => e
      #raise "IMAP: 接続に失敗 (Timeout::Error)"
      raise Sys::Lib::Net::Imap::Error.new("メールサーバーが混雑等の原因により遅延しているようです。しばらく時間をおいてからアクセスしてください。")
    rescue SocketError => e
      raise "IMAP: DNSエラー (SocketError)"
    rescue Exception => e
      raise "IMAP: エラー (#{e})"
    end
  end
end
