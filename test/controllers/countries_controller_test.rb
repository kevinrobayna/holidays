require "test_helper"

class CountriesControllerTest < ActionDispatch::IntegrationTest
  COUNTRIES = [
    Country.new(country_code: "ES", name: "Spain"),
    Country.new(country_code: "GB", name: "United Kingdom")
  ].freeze

  GB_HOLIDAYS = [
    Holiday.new(
      date: Date.new(2026, 1, 1),
      local_name: "New Year's Day",
      name: "New Year's Day",
      country_code: "GB",
      fixed: true,
      global: true,
      counties: nil,
      launch_year: nil,
      types: [ "Public" ]
    )
  ].freeze

  def stub_class_method(klass, method, replacement)
    sclass = klass.singleton_class
    original = sclass.instance_method(method)
    sclass.define_method(method, &replacement)
    yield
  ensure
    sclass.define_method(method, original) if original
  end

  def with_stubs(countries: COUNTRIES, holidays: GB_HOLIDAYS, captured: nil)
    stub_class_method(CountryFetcher, :call, ->(*) { countries }) do
      stub_class_method(HolidayFetcher, :call, lambda { |**kwargs|
        captured&.replace(kwargs)
        holidays
      }) do
        yield
      end
    end
  end

  test "GET /:country_code (lowercase) renders the country name" do
    with_stubs do
      get "/es"
    end

    assert_response :ok
    assert_includes response.body, "Spain"
  end

  test "GET /:country_code (uppercase) is normalised to upcase before lookup" do
    captured = {}
    with_stubs(captured: captured) do
      get "/GB"
    end

    assert_response :ok
    assert_equal "GB", captured[:country_code]
  end

  test "country_path helper produces lowercase 2-letter path" do
    assert_equal "/es", Rails.application.routes.url_helpers.country_path(country_code: "es")
  end

  test "GET /:country_code returns 404 for non-2-letter input" do
    get "/abc"
    assert_response :not_found

    get "/a"
    assert_response :not_found
  end

  test "GET /:country_code returns 404 for digits" do
    get "/12"
    assert_response :not_found
  end

  test "GET /:country_code returns 404 when country is not supported by Nager.Date" do
    holiday_calls = 0
    stub_class_method(CountryFetcher, :call, ->(*) { COUNTRIES }) do
      stub_class_method(HolidayFetcher, :call, ->(**) { holiday_calls += 1; [] }) do
        get "/zz"
      end
    end

    assert_response :not_found
    assert_equal 0, holiday_calls, "HolidayFetcher must not be called for unsupported countries"
  end

  test "GET /:country_code without ?year defaults to the current year" do
    captured = {}
    with_stubs(captured: captured) do
      get "/gb"
    end

    assert_response :ok
    assert_equal Time.current.year, captured[:year]
  end

  test "GET /:country_code?year=2025 fetches holidays for the requested year" do
    captured = {}
    with_stubs(captured: captured) do
      get "/gb?year=2025"
    end

    assert_response :ok
    assert_equal 2025, captured[:year]
  end

  test "GET /:country_code?year=abc returns 404 (non-integer year)" do
    holiday_calls = 0
    stub_class_method(CountryFetcher, :call, ->(*) { COUNTRIES }) do
      stub_class_method(HolidayFetcher, :call, ->(**) { holiday_calls += 1; [] }) do
        get "/gb?year=abc"
      end
    end

    assert_response :not_found
    assert_equal 0, holiday_calls
  end

  test "GET /:country_code?year=1900 returns 404 (outside HolidayFetcher::YEAR_RANGE)" do
    with_stubs do
      get "/gb?year=1900"
    end

    assert_response :not_found
  end

  test "GET /:country_code?year=2300 returns 404 (outside HolidayFetcher::YEAR_RANGE)" do
    with_stubs do
      get "/gb?year=2300"
    end

    assert_response :not_found
  end

  test "renders all twelve month names and the holiday's local name" do
    with_stubs do
      get "/gb?year=2026"
    end

    %w[January February March April May June July August September October November December].each do |month_name|
      assert_includes response.body, month_name, "expected month #{month_name} to be rendered"
    end

    assert_select "li", text: /New Year's Day/
  end

  test "renders prev and next year navigation links" do
    with_stubs do
      get "/gb?year=2026"
    end

    assert_select "a[href=?]", "/gb?year=2025"
    assert_select "a[href=?]", "/gb?year=2027"
  end

  test "hides previous year link when prev year would be outside YEAR_RANGE" do
    with_stubs do
      get "/gb?year=#{HolidayFetcher::YEAR_RANGE.first}"
    end

    assert_response :ok
    assert_select "a[rel=prev]", false, "prev year link should be hidden at the lower bound"
  end

  test "holiday days are wrapped in a <time> element with a screen-reader label" do
    with_stubs do
      get "/gb?year=2026"
    end

    # Sighted users see the highlighted cell; assistive tech gets the holiday name
    # via a visually-hidden span so we don't rely on color or `title` alone.
    assert_select "time[datetime=?]", "2026-01-01"
    assert_select "time[datetime=?] span.sr-only", "2026-01-01", text: /Public holiday: New Year's Day/
  end

  test "holiday days carry a non-color (dot) indicator" do
    with_stubs do
      get "/gb?year=2026"
    end

    # The dot is decorative-only (aria-hidden) but provides a visual cue
    # independent of background color for color-blind users.
    assert_select "time[datetime=?] span[aria-hidden=true]", "2026-01-01"
  end

  test "non-holiday days do not carry the dot indicator" do
    with_stubs do
      get "/gb?year=2026"
    end

    assert_select "time[datetime=?] span[aria-hidden=true]", "2026-01-02", count: 0
    assert_select "time[datetime=?] span.sr-only", "2026-01-02", count: 0
  end

  test "out-of-month padding cells are aria-hidden" do
    with_stubs do
      get "/gb?year=2026"
    end

    # Jan 2026 starts on a Thursday, so Mon Dec 29 2025 is a leading padding cell.
    assert_select "time[datetime=?][aria-hidden=true]", "2025-12-29"
  end
end
