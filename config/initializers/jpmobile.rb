Rails.application.config.jpmobile.mobile_filter
Rails.application.config.jpmobile.form_accept_charset_conversion = true

case Joruri.config.application['sys.force_site']
when 'mobile'
  module Jpmobile::Mobile
    class Others < SmartPhone
      USER_AGENT_REGEXP = /./
    end
  end
  module Jpmobile::Mobile
    @carriers << 'Others'
  end
when 'pc'
  module Jpmobile::Mobile
    @carriers = []
  end
end
