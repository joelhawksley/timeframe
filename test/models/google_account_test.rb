# frozen_string_literal: true

require "test_helper"

class GoogleAccountTest < ActiveSupport::TestCase
  def test_token_expired_returns_true_when_expired
    account = Account.find_or_create_by!(name: "GA Test")
    ga = GoogleAccount.create!(
      account: account,
      google_uid: "test_uid_#{SecureRandom.hex(4)}",
      email: "test@gmail.com",
      access_token: "access",
      refresh_token: "refresh",
      token_expires_at: 1.hour.ago
    )
    assert ga.token_expired?
  end

  def test_token_expired_returns_false_when_not_expired
    account = Account.find_or_create_by!(name: "GA Test")
    ga = GoogleAccount.create!(
      account: account,
      google_uid: "test_uid_#{SecureRandom.hex(4)}",
      email: "test2@gmail.com",
      access_token: "access",
      refresh_token: "refresh",
      token_expires_at: 1.hour.from_now
    )
    refute ga.token_expired?
  end

  def test_token_expired_returns_false_when_nil
    account = Account.find_or_create_by!(name: "GA Test")
    ga = GoogleAccount.create!(
      account: account,
      google_uid: "test_uid_#{SecureRandom.hex(4)}",
      email: "test3@gmail.com",
      access_token: "access",
      refresh_token: "refresh",
      token_expires_at: nil
    )
    refute ga.token_expired?
  end

  def test_valid_access_token_returns_token_when_not_expired
    account = Account.find_or_create_by!(name: "GA Test")
    ga = GoogleAccount.create!(
      account: account,
      google_uid: "test_uid_#{SecureRandom.hex(4)}",
      email: "test4@gmail.com",
      access_token: "my_access_token",
      refresh_token: "refresh",
      token_expires_at: 1.hour.from_now
    )
    assert_equal "my_access_token", ga.valid_access_token
  end

  def test_refresh_access_token_calls_oauth
    account = Account.find_or_create_by!(name: "GA Test")
    ga = GoogleAccount.create!(
      account: account,
      google_uid: "test_uid_#{SecureRandom.hex(4)}",
      email: "test5@gmail.com",
      access_token: "old_token",
      refresh_token: "refresh",
      token_expires_at: 1.hour.ago
    )

    new_token = OpenStruct.new(token: "new_token", refresh_token: "new_refresh", expires_at: 1.hour.from_now.to_i)
    mock_access_token = Minitest::Mock.new
    mock_access_token.expect(:refresh!, new_token)

    ENV["GOOGLE_CLIENT_ID"] = "test_id"
    ENV["GOOGLE_CLIENT_SECRET"] = "test_secret"
    OAuth2::AccessToken.stub(:new, mock_access_token) do
      ga.refresh_access_token!
    end

    assert_equal "new_token", ga.access_token
  ensure
    ENV.delete("GOOGLE_CLIENT_ID")
    ENV.delete("GOOGLE_CLIENT_SECRET")
  end
end
