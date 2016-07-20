require 'net/imap'
module Net
  class IMAP
    # CAPABILITY cache
    def capabilities
      @capabilities ||= capability
    end

    # LIST-STATUS [RFC5819]
    def list_status(refname, mailbox, status)
      synchronize do
        send_command("LIST", refname, mailbox, RawData.new("RETURN (STATUS (#{status.join(' ')}))"))
        list_responses = @responses.delete("LIST")
        status_responses = @responses.delete("STATUS")
        return list_responses, status_responses
      end
    end

    # X-MAILBOX and X-REAL-UID response for virtual mailboxes
    class ResponseParser
      private
      def msg_att(n)
        match(T_LPAR)
        attr = {}
        while true
          token = lookahead
          case token.symbol
          when T_RPAR
            shift_token
            break
          when T_SPACE
            shift_token
            next
          end
          case token.value
          when /\A(?:ENVELOPE)\z/ni
            name, val = envelope_data
          when /\A(?:FLAGS)\z/ni
            name, val = flags_data
          when /\A(?:INTERNALDATE)\z/ni
            name, val = internaldate_data
          when /\A(?:RFC822(?:\.HEADER|\.TEXT)?)\z/ni
            name, val = rfc822_text
          when /\A(?:RFC822\.SIZE)\z/ni
            name, val = rfc822_size
          when /\A(?:BODY(?:STRUCTURE)?)\z/ni
            name, val = body_data
          when /\A(?:UID)\z/ni
            name, val = uid_data
          # patch start
          when /\A(?:X-MAILBOX)\z/ni
            name, val = mailbox_string
          when /\A(?:X-REAL-UID)\z/ni
            name, val = uid_data
          # patch end
          else
            parse_error("unknown attribute `%s' for {%d}", token.value, n)
          end
          attr[name] = val
        end
        return attr
      end

      # patch start
      def mailbox_string
        token = match(T_ATOM)
        name = token.value.upcase
        match(T_SPACE)
        return name, astring
      end
      # patch end
    end
  end
end
