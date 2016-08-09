module Joruri
  class Initializer
    def initialize(app)
      @app = app
    end
  
    def call(env)
      Core.initialize(env)
      Core.recognize_path(env['PATH_INFO'])
      ret = @app.call(env)
      Core.terminate
      ret
    end
  end
end

Rails.application.config.middleware.use Joruri::Initializer
