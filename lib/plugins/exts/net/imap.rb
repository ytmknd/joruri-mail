require 'net/imap'
module Net
  module IMAPFix
    def select(mailbox)
      ret = super
      @selected_mailbox = mailbox
      @examined_mailbox = nil
      ret
    end

    def examine(mailbox)
      ret = super
      @selected_mailbox = nil
      @examined_mailbox = mailbox
      ret
    end

    def close
      ret = super
      @selected_mailbox = nil
      @examined_mailbox = nil
      ret
    end

    def selected?(mailbox)
      @selected_mailbox == mailbox
    end

    def examined?(mailbox)
      @examined_mailbox == mailbox
    end

    def opened?(mailbox)
      selected?(mailbox) || examined?(mailbox)
    end
  end

  class IMAP
    prepend IMAPFix

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

    # ESORT [RFC5267]
    def uid_esort(sort_keys, search_keys, charset, returns)
      if search_keys.instance_of?(String)
        search_keys = [RawData.new(search_keys)]
      else
        normalize_searching_criteria(search_keys)
      end
      normalize_searching_criteria(search_keys)

      synchronize do
        send_command("UID SORT", Net::IMAP::RawData.new("RETURN (#{returns})"), sort_keys, charset, *search_keys)
        response = @responses.delete("ESEARCH")[0]
        matches = response.scan(/UID\s+(?=.*(COUNT)\s(\d+))?(?=.*(MIN)\s(\d+))?(?=.*(MAX)\s(\d+))?(?=.*(PARTIAL)\s\(([^)]+)\))?/).first.compact
        if matches.size > 0
          hash = Hash[*matches]
          hash['PARTIAL'] = extend_partial_uids(hash['PARTIAL'].split(' ')[1]) if hash['PARTIAL']
          ['COUNT', 'MIN', 'MAX'].each { |key| hash[key] = hash[key].to_i if hash[key] }  
          return hash
        else
          raise ResponseParseError, format("invalid esearch result - %s", response)
        end
      end
    end

    def extend_partial_uids(str)
      return [] if str.nil? || str.empty?
      uids = []
      str.split(',').each do |value|
        next if value == 'NIL'
        array = value.split(':').map(&:to_i)
        uids += Range.new(array[0], array[-1]).to_a
      end
      uids
    end

    # SPECIAL-USE [RFC6154]
    module ResponseParserFixForSpecialUse
      def mailbox_list
        list = super
        list.class.instance_eval { attr_accessor :special_use }
        special_uses = [:Archive, :Drafts, :Sent, :Junk, :Trash, :All, :Flagged, :Important]
        list.special_use = (list.attr & special_uses).first
        list
      end
    end
    class ResponseParser
      prepend ResponseParserFixForSpecialUse
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
