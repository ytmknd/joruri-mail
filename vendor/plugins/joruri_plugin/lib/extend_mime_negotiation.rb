module ActionDispatch
  module Http
    module MimeNegotiation
      def formats
        accept = @env['HTTP_ACCEPT']
        
        if accept && accept !~ /,\s*\*\/\*/
          accept += ", */*"
        end
        
        @env["action_dispatch.request.formats"] ||=
          if parameters[:format]
            Array(Mime[parameters[:format]])
          elsif xhr? || (accept && accept !~ /,\s*\*\/\*/)
            accepts
          else
            [Mime::HTML]
          end
      end
    end
  end
end