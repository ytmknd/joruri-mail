module UrlHelper
  def url_for(options = nil)
    options = controller.url_options_with_keep_params(options) if options.is_a?(Hash)
    super
  end
end
