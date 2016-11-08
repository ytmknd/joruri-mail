module Util::Syslog
  class << self
    def info(message, options = {})
      return unless syslog_enabled?

      log = message
      log << ": #{options_to_string(options)}"  if options.present?
      Syslog.open('jorurimail') { |syslog| syslog.log(Syslog::LOG_INFO, log) }
    end

    private

    def syslog_enabled?
      Joruri.config.application['sys.use_syslog'] == 1
    end

    def options_to_string(options)
      options.to_a.map { |array| array.join('=') }.join(', ')
    end
  end
end
