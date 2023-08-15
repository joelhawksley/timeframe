# frozen_string_literal: true

require "test_helper"

class CalendarEventTest < Minitest::Test
  def test_assigns_time
    event = CalendarEvent.new(
      start_i: 1675123200,
      end_i: 1675126800,
      summary: "foo",
    ).to_h

    assert_equal("5 - 6p", event[:time])
  end

  def test_sets_multi_day
    event = CalendarEvent.new(
      start_i: 1675123200,
      end_i: 1675209601,
      summary: "foo",
    ).to_h

    assert_equal(true, event[:multi_day])
  end

  def test_sets_counter
    event = CalendarEvent.new(
      start_i: 1675123200,
      end_i: 1675209601,
      summary: "foo",
      description: (Date.today.year - 2).to_s,
    ).to_h

    assert_equal("foo (2)", event[:summary])
  end
end
