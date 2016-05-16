require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Joruri
  class Application < Rails::Application
    require "#{Rails.root}/lib/joruri"

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.

    # Custom directories with classes and modules you want to be autoloadable.
    config.autoload_paths += %W(#{config.root}/lib)

    # Set Time.zone default to the specified zone and make Active Record auto-convert to this zone.
    # Run "rake -D time" for a list of tasks for finding time zone names. Default is UTC.
    # config.time_zone = 'Central Time (US & Canada)'
    config.time_zone = "Tokyo"
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false

    # The default locale is :en and all translations from config/locales/*.rb,yml are auto loaded.
    # config.i18n.load_path += Dir[Rails.root.join('my', 'locales', '*.{rb,yml}').to_s]
    # config.i18n.default_locale = :de
    config.i18n.load_path += Dir[Rails.root.join('config', 'modules', '**', 'translation_ja.yml').to_s]
    config.i18n.default_locale = :ja

    # Do not swallow errors in after_commit/after_rollback callbacks.
    config.active_record.raise_in_transactional_callbacks = true

    # JavaScript files you want as :defaults (application.js is always included).
    # config.action_view.javascript_expansions[:defaults] = %w(jquery rails)

    # Load settings
    def load_settings(filename)
      YAML::load(ERB.new(File.read(Rails.root.join(filename))).result)[Rails.env].with_indifferent_access
    end
    config.action_mailer.smtp_settings = load_settings('config/smtp.yml')
    Joruri.config.imap_settings = load_settings('config/imap.yml')
    Joruri.config.sso_settings = load_settings('config/sso.yml')
  end
end
