# frozen_string_literal: true

require "test_helper"
require "capybara/minitest"
require "capybara/cuprite"

Capybara.register_driver :cuprite do |app|
  Capybara::Cuprite::Driver.new(app, headless: true, window_size: [1400, 900])
end

Capybara.default_driver = :cuprite
Capybara.javascript_driver = :cuprite
Capybara.default_max_wait_time = 5

# Allow VCR to pass through localhost requests from Capybara/Cuprite
VCR.configure do |config|
  config.ignore_localhost = true
end

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :cuprite

  def setup
    WebMock.allow_net_connect!
    Rack::Attack.reset!
  end

  def teardown
    WebMock.disable_net_connect!
  end
end
