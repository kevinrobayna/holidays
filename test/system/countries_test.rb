require "application_system_test_case"

class CountriesSystemTest < ApplicationSystemTestCase
  COUNTRIES_PAYLOAD = [
    { "countryCode" => "GB", "name" => "United Kingdom" },
    { "countryCode" => "ES", "name" => "Spain" }
  ].freeze

  GB_HOLIDAYS_PAYLOAD = [
    {
      "date" => "2026-01-01",
      "localName" => "New Year's Day",
      "name" => "New Year's Day",
      "countryCode" => "GB",
      "fixed" => true,
      "global" => true,
      "counties" => nil,
      "launchYear" => nil,
      "types" => [ "Public" ]
    },
    {
      "date" => "2026-03-17",
      "localName" => "St Patrick's Day",
      "name" => "St Patrick's Day",
      "countryCode" => "GB",
      "fixed" => true,
      "global" => false,
      "counties" => [ "GB-NIR" ],
      "launchYear" => nil,
      "types" => [ "Public" ]
    },
    {
      "date" => "2026-12-25",
      "localName" => "Christmas Day",
      "name" => "Christmas Day",
      "countryCode" => "GB",
      "fixed" => true,
      "global" => true,
      "counties" => nil,
      "launchYear" => nil,
      "types" => [ "Public" ]
    }
  ].freeze

  setup do
    stub_request(:get, "https://date.nager.at/api/v3/AvailableCountries")
      .to_return(status: 200, body: COUNTRIES_PAYLOAD.to_json, headers: { "Content-Type" => "application/json" })
    stub_request(:get, "https://date.nager.at/api/v3/PublicHolidays/2026/GB")
      .to_return(status: 200, body: GB_HOLIDAYS_PAYLOAD.to_json, headers: { "Content-Type" => "application/json" })
  end

  test "/:country_code calendar page is axe-clean" do
    visit "/gb?year=2026"

    assert_text "United Kingdom"
    assert_text "January"
    # Stub fixture covers both nationwide and regional badges, so the audit
    # exercises the contrast on both pill colour schemes.
    assert_text "Nationwide"
    assert_text "Regional: NIR"
    assert_accessible
  end
end
