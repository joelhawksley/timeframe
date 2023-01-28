require "test_helper"

class HelperTests
  include ApplicationHelper
end

class ApplicationHelperTest < Minitest::Test
  def setup
    @helper = HelperTests.new
  end

  def test_pregnancy_string
    assert_equal("15w6d", @helper.pregnancy_string(Date.parse("2022-12-21"), "2022-09-01"))
  end

  def test_pregnancy_no_remainder
    assert_equal("17w", @helper.pregnancy_string(Date.parse("2022-12-24"), "2022-08-27"))
  end
end
