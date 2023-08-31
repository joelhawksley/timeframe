# frozen_string_literal: true

require "test_helper"

class CalendarServiceTest < Minitest::Test
  include ActiveSupport::Testing::TimeHelpers

  def test_baby_age_event
    result = CalendarService.baby_age_event(Date.today - 7.days)

    assert_equal("1w", result.to_h[:summary])
  end

  def test_baby_age_event_weeks_days
    result = CalendarService.baby_age_event(Date.today - 8.days)

    assert_equal("1w1d", result.to_h[:summary])
  end

  def test_baby_age_event_less_than_one_week
    result = CalendarService.baby_age_event(Date.today - 6.days)

    assert_equal("6d", result.to_h[:summary])
  end

  def test_baby_age_event_works_in_evening
    travel_to DateTime.new(2023,8,27,20,20,0,"-0600") do
      result = CalendarService.baby_age_event(Date.today - 7.days)

      assert_equal(27, result.to_h[:starts_at].day)
      assert_equal(28, result.to_h[:ends_at].day)
    end
  end
end