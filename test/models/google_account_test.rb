# frozen_string_literal: true

require "test_helper"

class GoogleAccountTest < Minitest::Test
  def test_healthy_no_data
    account = GoogleAccount.create(email: "foo")

    assert(account.healthy?)
  end

  def test_healthy_with_log
    account = GoogleAccount.create(email: "foo")

    Log.create(globalid: account.to_global_id.to_s, event: "fetch_success", message: "bar")

    assert(account.healthy?)
  end
end