require "test_helper"

class TimeDifferenceTest < Minitest::Test
  def test_returns_a_new_TimeDifference_instance_in_each_component
    start_time = DateTime.new(2011, 1)
    end_time = DateTime.new(2011, 12)

    assert_instance_of TimeDifference, TimeDifference.between(start_time, end_time)
  end

  def test_returns_time_difference_in_each_component
    start_time = DateTime.new(2011, 1)
    end_time = DateTime.new(2011, 12)

    expected = {years: 0.91, months: 11, weeks: 47.71, days: 334.0, hours: 8016.0, minutes: 480960.0, seconds: 28857600.0}
    assert_equal expected, TimeDifference.between(start_time, end_time).in_each_component
  end

  def test_returns_time_difference_in_general_that_matches_the_total_seconds
    start_time = DateTime.new(2009, 11)
    end_time = DateTime.new(2011, 1)

    expected = {years: 1, months: 2, weeks: 0, days: 0, hours: 0, minutes: 0, seconds: 0}
    assert_equal expected, TimeDifference.between(start_time, end_time).in_general
  end

  def test_returns_a_string_representing_the_time_difference_from_in_general
    start_time = DateTime.new(2009, 11)
    end_time = DateTime.new(2011, 1)

    assert_equal "1 Year and 2 Months", TimeDifference.between(start_time, end_time).humanize
  end

  def test_humanize_returns_single_component_when_only_one_time_unit_exists
    start_time = DateTime.new(2023, 1, 1, 12, 0, 0)
    end_time = DateTime.new(2023, 1, 1, 15, 0, 0)

    assert_equal "3 Hours", TimeDifference.between(start_time, end_time).humanize
  end

  def test_returns_time_difference_in_years_based_on_Wolfram_Alpha
    start_time = DateTime.new(2011, 1)
    end_time = DateTime.new(2011, 12)

    assert_equal 0.91, TimeDifference.between(start_time, end_time).in_years
  end

  def test_returns_an_absolute_difference_years
    start_time = DateTime.new(2011, 12)
    end_time = DateTime.new(2011, 1)

    assert_equal 0.91, TimeDifference.between(start_time, end_time).in_years
  end

  def test_returns_time_difference_in_months_based_on_Wolfram_Alpha
    start_time = DateTime.new(2011, 1)
    end_time = DateTime.new(2011, 12)

    assert_equal 11, TimeDifference.between(start_time, end_time).in_months
  end

  def test_returns_an_absolute_difference_months
    start_time = DateTime.new(2011, 12)
    end_time = DateTime.new(2011, 1)

    assert_equal(-11, TimeDifference.between(start_time, end_time).in_months)
  end

  def test_returns_time_difference_in_weeks_based_on_Wolfram_Alpha
    start_time = DateTime.new(2011, 1)
    end_time = DateTime.new(2011, 12)

    assert_equal 47.71, TimeDifference.between(start_time, end_time).in_weeks
  end

  def test_returns_an_absolute_difference_weeks
    start_time = DateTime.new(2011, 12)
    end_time = DateTime.new(2011, 1)

    assert_equal 47.71, TimeDifference.between(start_time, end_time).in_weeks
  end

  def test_returns_time_difference_in_days_based_on_Wolfram_Alpha
    start_time = DateTime.new(2011, 1)
    end_time = DateTime.new(2011, 12)

    assert_equal 334.0, TimeDifference.between(start_time, end_time).in_days
  end

  def test_returns_an_absolute_difference_days
    start_time = DateTime.new(2011, 12)
    end_time = DateTime.new(2011, 1)

    assert_equal 334.0, TimeDifference.between(start_time, end_time).in_days
  end

  def test_returns_time_difference_in_hours_based_on_Wolfram_Alpha
    start_time = DateTime.new(2011, 1)
    end_time = DateTime.new(2011, 12)

    assert_equal 8016.0, TimeDifference.between(start_time, end_time).in_hours
  end

  def test_returns_an_absolute_difference_hours
    start_time = DateTime.new(2011, 12)
    end_time = DateTime.new(2011, 1)

    assert_equal 8016.0, TimeDifference.between(start_time, end_time).in_hours
  end

  def test_returns_time_difference_in_minutes_based_on_Wolfram_Alpha
    start_time = DateTime.new(2011, 1)
    end_time = DateTime.new(2011, 12)

    assert_equal 480960.0, TimeDifference.between(start_time, end_time).in_minutes
  end

  def test_returns_an_absolute_difference_minutes
    start_time = DateTime.new(2011, 12)
    end_time = DateTime.new(2011, 1)

    assert_equal 480960.0, TimeDifference.between(start_time, end_time).in_minutes
  end

  def test_returns_time_difference_in_seconds_based_on_Wolfram_Alpha
    start_time = DateTime.new(2011, 1)
    end_time = DateTime.new(2011, 12)

    assert_equal 28857600.0, TimeDifference.between(start_time, end_time).in_seconds
  end

  def test_returns_an_absolute_difference
    start_time = DateTime.new(2011, 12)
    end_time = DateTime.new(2011, 1)

    assert_equal 28857600.0, TimeDifference.between(start_time, end_time).in_seconds
  end

  def test_considers_Sep_4_to_Dec_4_to_be_3_months
    start_time = DateTime.new(2017, 9, 4)
    end_time = DateTime.new(2017, 12, 4)

    assert_equal 3, TimeDifference.between(start_time, end_time).in_months
  end

  def test_considers_Aug_4_to_Nov_4_to_be_3_months
    start_time = DateTime.new(2017, 8, 4)
    end_time = DateTime.new(2017, 11, 4)

    assert_equal 3, TimeDifference.between(start_time, end_time).in_months
  end

  def test_considers_Sep_4_to_Dec_3_to_be_2_months
    start_time = DateTime.new(2017, 9, 4)
    end_time = DateTime.new(2017, 12, 3)

    assert_equal 2, TimeDifference.between(start_time, end_time).in_months
  end

  def test_considers_Sep_4_to_Dec_31_to_be_3_months
    start_time = DateTime.new(2017, 9, 4)
    end_time = DateTime.new(2017, 12, 31)

    assert_equal 3, TimeDifference.between(start_time, end_time).in_months
  end

  def test_considers_2016_Sep_4_to_2017_Sep_4_to_be_12_months
    start_time = DateTime.new(2016, 9, 4)
    end_time = DateTime.new(2017, 9, 4)

    assert_equal 12, TimeDifference.between(start_time, end_time).in_months
  end

  def test_considers_2016_Sep_4_to_2017_Dec_31_to_be_15_months
    start_time = DateTime.new(2016, 9, 4)
    end_time = DateTime.new(2017, 12, 31)

    assert_equal 15, TimeDifference.between(start_time, end_time).in_months
  end

  def test_counts_months_on_the_day_when_time2_greater_than_time1
    start_time = Time.new(2017, 9, 4, 12, 15)
    end_time = Time.new(2017, 12, 4, 12, 22)

    assert_equal 3, TimeDifference.between(start_time, end_time).in_months
  end

  def test_does_not_count_months_on_the_day_when_time2_less_than_time1
    start_time = Time.new(2017, 9, 4, 12, 15)
    end_time = Time.new(2017, 12, 4, 12, 10)

    assert_equal 2, TimeDifference.between(start_time, end_time).in_months
  end
end
