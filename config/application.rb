require_relative 'boot'

# Keep Ruby 2.7 stdlib net/protocol loaded before bundled net-* gems. Otherwise
# css_parser's net/https load reopens the stdlib file after net-protocol.
require 'net/https'

require 'rails/all'

# shared-mime-info 0.2.5 is the last release and still calls a deprecated
# mime-types constructor while loading the freedesktop MIME database.
original_verbose = $VERBOSE
$VERBOSE = nil
require 'shared-mime-info'
$VERBOSE = original_verbose

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Joruri
  class Application < Rails::Application
    config.load_defaults 7.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
    require "#{Rails.root}/lib/joruri"

    if ENV['SECRET_KEY_BASE'].to_s != ''
      config.secret_key_base = ENV['SECRET_KEY_BASE']
    end

    config.autoloader = :zeitwerk
    Rails.autoloaders.main.ignore(Rails.root.join('lib/plugins'))

    # Custom directories with classes and modules you want to be autoloadable.
    config.eager_load_paths += %W(#{config.root}/lib)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false
    config.active_support.disable_to_s_conversion = true

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.load_path += Dir[Rails.root.join('config', 'modules', '**', 'locales', '*.yml').to_s]
    config.i18n.default_locale = :ja

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)
    config.action_view.field_error_proc = proc { |html_tag, instance|
      %Q|<span class="field_with_errors">#{html_tag}</span>|.html_safe
    }

    if ActiveJob::QueueAdapters.autoload?(:DelayedJobAdapter)
      ActiveJob::QueueAdapters.send(:remove_const, :DelayedJobAdapter)
      load File.join(Gem::Specification.find_by_name('activejob').full_gem_path, 'lib/active_job/queue_adapters/delayed_job_adapter.rb')
    end
    config.active_job.queue_adapter = :delayed_job
  end
end
