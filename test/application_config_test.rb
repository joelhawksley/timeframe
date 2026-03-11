# frozen_string_literal: true

require "test_helper"

class ApplicationConfigTest < Minitest::Test
  def test_load_config_with_supervisor_token
    ENV["SUPERVISOR_TOKEN"] = "test_token"
    config = Timeframe::Application.load_config
    assert_equal "test_token", config["home_assistant_token"]
    assert_equal "http://supervisor/core", config["home_assistant_url"]
  ensure
    ENV.delete("SUPERVISOR_TOKEN")
  end

  def test_load_config_with_supervisor_token_and_addon_options
    ENV["SUPERVISOR_TOKEN"] = "test_token"
    options = {}.to_json

    File.stub :exist?, ->(path) { path == "/data/options.json" } do
      File.stub :read, options, ["/data/options.json"] do
        config = Timeframe::Application.load_config
        assert_equal "test_token", config["home_assistant_token"]
      end
    end
  ensure
    ENV.delete("SUPERVISOR_TOKEN")
  end

  def test_load_config_with_config_yml
    ENV.delete("SUPERVISOR_TOKEN")
    config = Timeframe::Application.load_config
    assert config.key?("home_assistant_token")
  end

  def test_load_config_without_anything
    ENV.delete("SUPERVISOR_TOKEN")
    File.stub :exist?, false do
      config = Timeframe::Application.load_config
      assert_equal({}, config)
    end
  end
end
