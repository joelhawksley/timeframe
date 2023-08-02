# frozen_string_literal: true

require "test_helper"

class CalendarEventTest < Minitest::Test
  def test_assigns_time
    event = CalendarEvent.new(
      start_i: 1675123200,
      end_i: 1675126800,
      calendar: "test",
      summary: "foo",
    ).to_h

    assert_equal("5 - 6p", event[:time])
  end

  def test_sets_multi_day
    event = CalendarEvent.new(
      start_i: 1675123200,
      end_i: 1675209601,
      calendar: "test",
      summary: "foo",
    ).to_h

    assert_equal(true, event[:multi_day])
  end
end
