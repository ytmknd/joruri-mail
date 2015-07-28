# encoding: utf-8

#ActionController::Routing::Routes.instance_eval do
#  def recognize(request)
#    Core.initialize(request.env)
#    super(request)
#  end
#  
#  def recognize_path(path, environment={})
#    dump "------"
#    Core.recognize_path(path)
#    super(Core.internal_uri, environment)
#  end
#end

#ActionDispatch::Routing::RouteSet.instance_eval do
#      def recognize_path(path, environment = {})
#        dump "# recognize_path"
#        super
#      end
#end

module ActionDispatch
  module Routing
    class RouteSet
      def call(env)
#        dump "====================\n# call"
        Core.initialize(env)
        
        finalize!
        @set.call(env)
      end
      
      class Dispatcher
        def prepare_params!(params)
#          dump "# prepare_params"
          
          merge_default_action!(params)
          split_glob_param!(params) if @glob_param
        end
        
      protected
        def dispatch(controller, action, env)
#          dump "# dispatch"
          path = env['PATH_INFO']
          Core.recognize_path(path)
          
          rs = controller.action(action).call(env)
          Core.terminate
          rs
        end
      end
    end
  end
end