# frozen_string_literal: true

require "test_helper"

class WundergroundServiceTest < Minitest::Test
  def test_healthy_false_without_log
    assert_equal(false, WundergroundService.healthy?)
  end

  def test_healthy_false_with_old_log
    assert_equal(
      false,
      WundergroundService.healthy?(
        Log.new(
          globalid: 'WundergroundService',
          event: 'call_success',
          message: "foo",
          created_at: DateTime.now - 2.hours
        )
      )
    )
  end

  def test_healthy_with_log
    assert_equal(
      true,
      WundergroundService.healthy?(
        Log.new(
          globalid: 'WundergroundService',
          event: 'call_success',
          message: "foo",
          created_at: DateTime.now
        )
      )
    )
  end
end