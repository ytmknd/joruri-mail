module Rack
  class Request
    def initialize(env)
      @env = env
      @env["rack.input"].rewind if @env["rack.input"]
    end
  end
end