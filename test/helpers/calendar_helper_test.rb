require "test_helper"

class CalendarHelperTest < ActionView::TestCase
  test "returns 6 rows of 7 days" do
    weeks = month_weeks(2026, 5)

    assert_equal 6, weeks.size
    weeks.each { |row| assert_equal 7, row.size }
  end

  test "every cell is a Date" do
    month_weeks(2026, 5).flatten.each { |d| assert_kind_of Date, d }
  end

  test "first column is Monday" do
    weeks = month_weeks(2026, 5)

    weeks.each do |row|
      assert_equal 1, row.first.cwday, "row starts on #{row.first} (cwday #{row.first.cwday})"
    end
  end

  test "leading cells fall in the previous month when the month does not start on Monday" do
    # May 1, 2026 is a Friday (cwday 5), so 4 leading days come from April.
    weeks = month_weeks(2026, 5)
    first_row = weeks.first

    assert_equal Date.new(2026, 4, 27), first_row.first
    assert_equal Date.new(2026, 5, 1),  first_row[4]
  end

  test "no leading or trailing fill when the month starts on Monday and exactly fits" do
    # March 2026 starts on a Sunday and ends on Tuesday (cwday 2). It does not start
    # on Monday, but we can still verify the grid stays anchored to Monday.
    weeks = month_weeks(2026, 3)

    assert_equal Date.new(2026, 2, 23), weeks.first.first
    # Total span is 6*7 = 42 days starting from grid_start
    assert_equal Date.new(2026, 4, 5), weeks.last.last
  end

  test "January edge pulls in December of the previous year" do
    weeks = month_weeks(2026, 1)
    first = weeks.first.first

    assert_equal 2025, first.year
    assert_equal 12, first.month
  end

  test "December edge pushes into January of the next year" do
    weeks = month_weeks(2026, 12)
    last = weeks.last.last

    assert_equal 2027, last.year
    assert_equal 1, last.month
  end

  test "leap February (2024) includes Feb 29" do
    weeks = month_weeks(2024, 2)
    in_feb = weeks.flatten.select { |d| d.month == 2 }

    assert_includes in_feb, Date.new(2024, 2, 29)
    assert_equal 29, in_feb.size
  end
end
