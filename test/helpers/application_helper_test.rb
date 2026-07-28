require "test_helper"

class ApplicationHelperTest < ActionView::TestCase
  tests ApplicationHelper

  test "format_date_elegant spells the weekday and keeps the rest numeric" do
    assert_equal "Monday, 10 May 2027", format_date_elegant(Date.new(2027, 5, 10))
  end

  test "format_time_elegant spells afternoon times" do
    assert_equal "four thirty in the afternoon", format_time_elegant("4:30 PM")
    assert_equal "four o'clock in the afternoon", format_time_elegant("4:00 PM")
  end

  test "format_time_elegant spells evening and morning periods" do
    assert_equal "six o'clock in the evening", format_time_elegant("6:00 PM")
    assert_equal "ten o'clock in the morning", format_time_elegant("10:00 AM")
  end

  test "format_time_elegant returns nil for blank values" do
    assert_nil format_time_elegant(nil)
    assert_nil format_time_elegant("")
  end
end
