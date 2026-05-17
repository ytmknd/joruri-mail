if Rails.gem_version >= Gem::Version.new('6.0') && defined?(Jpmobile::Resolver)
  if Rails.gem_version >= Gem::Version.new('7.0') &&
      defined?(ActionView::LookupContext) &&
      !ActionView::LookupContext.registered_details.include?(:mobile)
    ActionView::LookupContext.register_detail(:mobile) { [] }

    module JpmobileRails7DetailsKey
      def details_cache_key(details)
        details = details.dup
        details.delete(:mobile)
        super(details)
      end
    end

    ActionView::LookupContext::DetailsKey.singleton_class.prepend(JpmobileRails7DetailsKey)
  end

  class Jpmobile::Resolver
    if Rails.gem_version >= Gem::Version.new('6.1')
      def initialize(path, pattern = nil)
        raise ArgumentError, 'path already is a Resolver class' if path.is_a?(Jpmobile::Resolver)
        super(path)
        @pattern = pattern || DEFAULT_PATTERN
      end
    end

    private

    def query(path, details, formats, locals = [], cache: false)
      template_paths = find_template_paths_from_details(path, details)
      template_paths = reject_files_external_to_app(template_paths)

      template_paths.map do |template|
        unbound_template =
          if cache
            @unbound_templates.compute_if_absent([template, path.virtual]) do
              build_unbound_template(template, path.virtual)
            end
          else
            build_unbound_template(template, path.virtual)
          end

        unbound_template.bind_locals(locals)
      end
    end
  end
end
