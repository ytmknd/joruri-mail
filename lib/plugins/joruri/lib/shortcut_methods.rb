def error_log(message)
  Rails.logger.error message
end

def debug_log(data)
  Rails.logger.debug data.pretty_inspect
end

def stdout_log(data)
  Logger.new(STDOUT).info data
end
