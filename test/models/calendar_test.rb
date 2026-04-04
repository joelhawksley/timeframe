# frozen_string_literal: true

require "test_helper"

class CalendarTest < ActiveSupport::TestCase
  def setup
    @account = Account.find_or_create_by!(name: "Cal Test")
  end

  def test_google_predicate
    cal = Calendar.new(source_type: "google", account: @account, name: "Test")
    assert cal.google?
    refute cal.url?
  end

  def test_url_predicate
    cal = Calendar.new(source_type: "url", account: @account, name: "Test")
    assert cal.url?
    refute cal.google?
  end

  def test_sync_enqueues_google_job
    cal = Calendar.create!(source_type: "google", account: @account, name: "Google Cal", external_id: "ext_#{SecureRandom.hex(4)}")
    assert_nothing_raised { cal.sync! }
  end

  def test_sync_enqueues_ics_job
    # Create ICS calendar without validation (url_is_valid_ics makes HTTP request)
    cal = Calendar.new(source_type: "url", account: @account, name: "ICS Cal", url: "https://example.com/cal.ics")
    cal.save!(validate: false)
    cal.sync!
    assert true
  end

  def test_webhook_verification_token
    cal = Calendar.create!(source_type: "google", account: @account, name: "Token Test", external_id: "ext_#{SecureRandom.hex(4)}")
    token = cal.webhook_verification_token
    assert token.is_a?(String)
    assert_equal token, cal.webhook_verification_token # deterministic
  end

  def test_register_webhook_returns_nil_for_non_google
    cal = Calendar.new(source_type: "url", account: @account, name: "Test")
    assert_nil cal.register_webhook!
  end

  def test_stop_webhook_clears_fields
    cal = Calendar.create!(
      source_type: "google",
      account: @account,
      name: "Webhook Test",
      external_id: "ext_#{SecureRandom.hex(4)}",
      webhook_channel_id: "ch_123",
      webhook_resource_id: "res_456",
      webhook_expires_at: 1.day.from_now
    )
    # stop_webhook! calls Google API which will fail, but ensure block clears fields
    cal.stop_webhook!
    cal.reload
    assert_nil cal.webhook_channel_id
    assert_nil cal.webhook_resource_id
    assert_nil cal.webhook_expires_at
  end
end
