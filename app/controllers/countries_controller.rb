class CountriesController < ApplicationController
  YEAR_PARAM_REGEX = /\A\d+\z/

  def show
    @country_code = params[:country_code].to_s.upcase
    @country = CountryFetcher.call.find { |c| c.country_code == @country_code }
    return head :not_found unless @country

    @year = parse_year(params[:year]) or return head :not_found

    @holidays = HolidayFetcher.call(country_code: @country_code, year: @year)
    @holidays_by_date = @holidays.group_by(&:date)
  end

  private

  def parse_year(raw)
    return Time.current.year if raw.blank?
    return nil unless raw.match?(YEAR_PARAM_REGEX)

    year = raw.to_i
    HolidayFetcher::YEAR_RANGE.cover?(year) ? year : nil
  end
end
