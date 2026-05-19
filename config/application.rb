require_relative "boot"

require "rails/all"

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
    config.load_defaults 8.1

    # lib/ is auto-loaded. lib/assets, lib/tasks, and lib/plugins are excluded:
    # plugins contains monkey patches and must not be auto-loaded by Zeitwerk.
    config.autoload_lib(ignore: %w[assets tasks plugins])

    require "#{Rails.root}/lib/joruri"

    if ENV['SECRET_KEY_BASE'].to_s != ''
      config.secret_key_base = ENV['SECRET_KEY_BASE']
    end

    config.time_zone = 'Tokyo'
    config.active_record.default_timezone = :local
    config.active_record.time_zone_aware_attributes = false

    config.i18n.load_path += Dir[Rails.root.join('config', 'modules', '**', 'locales', '*.yml').to_s]
    config.i18n.default_locale = :ja

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
