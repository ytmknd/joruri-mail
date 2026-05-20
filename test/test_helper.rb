ENV["RAILS_ENV"] ||= "test"
require File.expand_path('../../config/environment', __FILE__)
require 'rails/test_help'

class ActiveSupport::TestCase
  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  # Skipped outside the test environment so system tests driving a running
  # development server do not overwrite the dev database with fixtures.
  fixtures :all if Rails.env.test?

  # Add more helper methods to be used by all tests here...
end
