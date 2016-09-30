module Net
  module SMTPFix
    # fix for RCPT TO Extension
    def rcptto(to_addr)
      if to_addr.to_s =~ /^<[^>]+>/
        return getok("RCPT TO:#{to_addr}")
      end
      super
    end
  end
  class SMTP
    prepend SMTPFix
  end
end
