module UrlHelper
  def url_for(options = nil)
    options = controller.url_options_with_keep_params(options)

    if request.mobile? && options.is_a?(Hash)
      options.each do |key, value|
        options[key] = request.mobile.to_external(value, nil, nil).first if value.is_a?(String)
      end
    end

    super
  end
end
