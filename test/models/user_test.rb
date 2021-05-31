# frozen_string_literal: true

require "test_helper"

class UserTest < Minitest::Test
  def test_hardcoded_tz
    assert_equal(User.new.tz, "America/Denver")
  end
end
