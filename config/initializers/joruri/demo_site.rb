if Util::Config.load(:core)['mail_domain'] == 'demo.joruri.org'

  Mail::Message.class_eval do |cls|

    def delivery_handler
      cls = Class.new do

        def initialize
          @domain = Core.config['mail_domain']
        end

        def filter(f)
          return f.addrs if @domain.blank?
          filtered = []
          f.each do |addr|
            filtered << addr if addr.address =~ /[@\.]#{Regexp.escape(@domain)}$/i
          end
          filtered        
        end

        def deliver_mail(m)

          to = m.header[:to]
          cc = m.header[:cc]
          bcc = m.header[:bcc]
          m.to = filter(to).join(',') if to
          m.cc = filter(cc).join(',') if cc
          m.bcc = filter(bcc).join(',') if bcc

          yield        
        end
      end
      cls.new
    end
  end
end
