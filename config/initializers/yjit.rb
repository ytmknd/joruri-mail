if RUBY_VERSION >= "3.3" && defined?(RubyVM::YJIT)
  Rails.application.config.yjit = true
end
