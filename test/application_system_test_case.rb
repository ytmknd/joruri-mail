require "test_helper"
require "capybara"
require "capybara/dsl"
require "capybara/minitest"
require "selenium-webdriver"

# System tests drive a real browser via a remote Selenium service to exercise
# the running Phase 5 application. The tests target the live dev container
# (the same one verified manually at http://localhost:3009/), so they share
# its database. They are NOT loaded by the default `rails test` runner —
# invoke them explicitly via `rails test test/system` or the docker-phase5
# helper command.
class ApplicationSystemTestCase < ActiveSupport::TestCase
  include Capybara::DSL
  include Capybara::Minitest::Assertions

  SELENIUM_URL = ENV.fetch("SELENIUM_REMOTE_URL", "http://app-ubuntu26-ruby4-selenium:4444/wd/hub").freeze
  APP_HOST     = ENV.fetch("CAPYBARA_APP_HOST", "http://app-ubuntu26-ruby4:3000").freeze

  Capybara.register_driver :selenium_remote_chromium do |app|
    options = Selenium::WebDriver::Chrome::Options.new
    options.add_argument("--headless=new")
    options.add_argument("--no-sandbox")
    options.add_argument("--disable-dev-shm-usage")
    options.add_argument("--window-size=1280,1024")
    options.add_argument("--lang=ja-JP")

    Capybara::Selenium::Driver.new(
      app,
      browser: :remote,
      url: SELENIUM_URL,
      options: options,
    )
  end

  Capybara.app_host       = APP_HOST
  Capybara.run_server     = false
  Capybara.default_driver = :selenium_remote_chromium
  Capybara.default_max_wait_time = 15

  setup do
    Capybara.reset_sessions!
  end

  teardown do
    Capybara.reset_sessions!
  end

  private

  def login_as_admin
    visit "/_admin/login"
    fill_in "account",  with: "admin"
    fill_in "password", with: "admin"
    click_button "ログイン"
  end
end
