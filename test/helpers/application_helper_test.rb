require 'test_helper'

class HelperTests
  include ApplicationHelper
end

class ApplicationHelperTest < Minitest::Test
  def setup
    @helper = HelperTests.new
  end

  def test_pregnancy_string
    assert_equal(@helper.pregnancy_string(Date.parse("2022-12-21")), "11w4d")
  end
end