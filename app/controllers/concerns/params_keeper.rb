module ParamsKeeper

  def url_options_with_keep_params(options)
    options = keep_params(options)
    if request.mobile?
      options.each do |key, value|
        options[key] = request.mobile.to_external(value, nil, nil).first if value.is_a?(String)
      end
    end
    options
  end

  private

  def keep_params(options)
    options
  end

  def url_for(options = nil)
    options = url_options_with_keep_params(options) if options.is_a?(Hash)
    super
  end
end
