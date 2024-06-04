# frozen_string_literal: true

require "test_helper"

class GoogleAccountTest < Minitest::Test
  def test_is_healthy
    account = GoogleAccount.new
    account.stub(:last_fetched_at, (Time.now - 1.second).to_s) do
      account.stub(:refresh_token, "bar") do
        assert(account.healthy?)
      end
    end
  end

  def test_empty_events
    assert_equal([], GoogleAccount.create(email: "foo").events)
  end

  def test_empty_last_fetched_at
    assert_nil(GoogleAccount.create(email: "foo").last_fetched_at)
  end
end
