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
    assert_accessible
  end
end
