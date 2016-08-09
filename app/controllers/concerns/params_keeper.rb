module ParamsKeeper
  def url_options_with_keep_params(options)
    if options.is_a?(Hash)
      keep_params(options)
    else
      options
    end
  end

  private

  def keep_params(options)
    options
  end

  def url_for(options = nil)
    options = url_options_with_keep_params(options)
    super
  end
end
