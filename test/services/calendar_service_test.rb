# frozen_string_literal: true

require "test_helper"

class CalendarServiceTest < Minitest::Test
  def test_baby_age_string
    result = CalendarService.baby_age_string(Date.today - 7.days)

    assert_equal("1w", result)
  end

  def test_baby_age_string_weeks_days
    result = CalendarService.baby_age_string(Date.today - 8.days)

    assert_equal("1w1d", result)
  end

  def test_baby_age_string_less_than_one_week
    result = CalendarService.baby_age_string(Date.today - 6.days)

    assert_equal("6d", result)
  end
end