# Be sure to restart your server when you modify this file.

#Rails.application.config.session_store :cookie_store, key: '_joruri_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
Rails.application.config.session_store :active_record_store
Rails.application.config.session_options = { cookie_only: false }
db_configs = ActiveRecord::Base.configurations
has_session_config =
  if db_configs.respond_to?(:configs_for)
    db_configs.configs_for(env_name: 'session').any?
  else
    db_configs.key?('session')
  end
ActiveRecord::SessionStore::Session.establish_connection :session if has_session_config
ActiveRecord::SessionStore::Session.validates :session_id, presence: true
