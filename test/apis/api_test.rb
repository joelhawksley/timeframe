# frozen_string_literal: true

require "test_helper"

class ApiTest < Minitest::Test
  def test_url
    api = Api.new
    assert_nil api.url
  end

  def test_headers
    api = Api.new
    assert_equal({}, api.headers)
  end

  def test_time_before_unhealthy
    api = Api.new
    assert_equal 10.minutes, api.time_before_unhealthy
  end

  def test_prepare_response
    api = Api.new
    body = Struct.new(:body).new('{"key":"value"}')
    assert_equal({"key" => "value"}, api.prepare_response(body))
  end

  def test_home_assistant_base_url_without_config
    api = Api.new
    assert_equal "http://homeassistant.local:8123", api.home_assistant_base_url
  end

  def test_fetch_non_200
    api = HomeAssistantApi.new
    VCR.use_cassette(:home_assistant_states) do
      response = Struct.new(:code).new(500)
      HTTParty.stub :get, response do
        result = api.fetch
        assert_nil result
      end
    end
  end
end
