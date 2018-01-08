def error_log(message)
  Rails.logger.error "[ USER ERROR #{Time.now.strftime('%Y-%m-%d %H:%M:%S')} ]: #{message}"
end

def warn_log(message)
  Rails.logger.warn "[ WARN #{Time.now.strftime('%Y-%m-%d %H:%M:%S')} ]: #{message}"
end

def debug_log(data)
  Rails.logger.debug "[ DEBUG #{Time.now.strftime('%Y-%m-%d %H:%M:%S')} ]: #{data.pretty_inspect}"
end
