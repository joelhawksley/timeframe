# frozen_string_literal: true

require "test_helper"

class CalendarServiceTest < Minitest::Test
  def test_baby_age_string
    result = CalendarService.baby_age_string(Date.today - 7.days)

    assert_equal("1w", result)
  end

  def test_baby_age_string
    result = CalendarService.baby_age_string(Date.today - 6.days)

    assert_equal("6d", result)
  end
end