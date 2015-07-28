# Be sure to restart your server when you modify this file.

Joruri::Application.config.session_store :cookie_store, :key => '_joruri_session'

# Use the database for sessions instead of the cookie-based default,
# which shouldn't be used to store highly confidential information
# (create the session table with "rake db:sessions:create")
Joruri::Application.config.session_store :active_record_store
Joruri::Application.config.session_options = {:cookie_only => false}
ActiveRecord::SessionStore::Session.establish_connection :session rescue nil
ActiveRecord::SessionStore::Session.validates_presence_of :session_id