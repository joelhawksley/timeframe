# frozen_string_literal: true

require "test_helper"

class DisplayContenttTest < Minitest::Test
  def test_no_data
    result = DisplayContent.new.call

    assert_nil(result[:current_temperature])
  end
end