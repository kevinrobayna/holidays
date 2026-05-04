module CalendarHelper
  WEEKS_PER_GRID = 6
  DAYS_PER_WEEK = 7
  ISO_COUNTRY_PREFIX = /\A[A-Z]{2}-/

  def month_weeks(year, month)
    first = Date.new(year, month, 1)
    grid_start = first - (first.cwday - 1)
    Array.new(WEEKS_PER_GRID) do |row|
      Array.new(DAYS_PER_WEEK) { |col| grid_start + (row * DAYS_PER_WEEK) + col }
    end
  end

  def holiday_scope_text(holiday)
    return "Nationwide" if holiday.global
    return nil if holiday.counties.blank?

    short = holiday.counties.map { |code| code.sub(ISO_COUNTRY_PREFIX, "") }
    "Regional: #{short.join(', ')}"
  end
end
