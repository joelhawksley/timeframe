# frozen_string_literal: true

require "test_helper"

class EventTimeServiceTest < Minitest::Test
  def test_one_hour_event_in_afternoon_at_top_of_hour
    start = 1621288800 # 4pm
    finish = 1621292400 # 5pm

    result = EventTimeService.call(start, finish, "America/Denver")

    assert_equal("4 - 5p", result)
  end

  def test_one_hour_event_in_afternoon_at_minute_past_hour
    start = 1621288860 # 4:01pm
    finish = 1621292460 # 5:01pm

    result = EventTimeService.call(start, finish, "America/Denver")

    assert_equal("4:01 - 5:01p", result)
  end

  def test_event_with_same_start_and_end_at_top_of_hour
    start = 1621288800 # 4pm

    result = EventTimeService.call(start, start, "America/Denver")

    assert_equal("4p", result)
  end

  def test_event_with_same_start_and_end_at_minute_past
    start = 1621288860 # 4:01pm

    result = EventTimeService.call(start, start, "America/Denver")

    assert_equal("4:01p", result)
  end

  def test_event_morning_to_afternoon
    start = 1621260000 # 8am
    finish = 1621288800 # 4pm

    result = EventTimeService.call(start, finish, "America/Denver")

    assert_equal("8a - 4p", result)
  end

  def test_event_morning_to_afternoon_off_minute
    start = 1621260060 # 8:01am
    finish = 1621288860 # 4:01pm

    result = EventTimeService.call(start, finish, "America/Denver")

    assert_equal("8:01a - 4:01p", result)
  end

  def test_event_different_days_off_by_minutes
    start = 1621220000 # 8:53am 5/16/21
    finish = 1621288800 # 4pm 5/17

    result = EventTimeService.call(start, finish, "America/Denver")

    assert_equal("5/16 8:53p - 5/17 4p", result)
  end

  def test_event_different_days
    start = 1621216820 # 8am 5/16/21
    finish = 1621288800 # 4pm 5/17

    result = EventTimeService.call(start, finish, "America/Denver")

    assert_equal("5/16 8p - 5/17 4p", result)
  end
end
