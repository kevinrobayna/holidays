require "test_helper"

class HolidayTest < ActiveSupport::TestCase
  test "from_api maps Nager payload onto snake_case attributes and parses date" do
    payload = {
      "date" => "2026-01-06",
      "localName" => "Día de Reyes",
      "name" => "Epiphany",
      "countryCode" => "ES",
      "fixed" => true,
      "global" => true,
      "counties" => nil,
      "launchYear" => nil,
      "types" => [ "Public" ]
    }

    holiday = Holiday.from_api(payload)

    assert_equal Date.new(2026, 1, 6), holiday.date
    assert_equal "Día de Reyes", holiday.local_name
    assert_equal "Epiphany", holiday.name
    assert_equal "ES", holiday.country_code
    assert_equal true, holiday.fixed
    assert_equal true, holiday.global
    assert_nil holiday.counties
    assert_nil holiday.launch_year
    assert_equal [ "Public" ], holiday.types
  end

  test "from_api preserves non-global subdivision data" do
    payload = {
      "date" => "2026-04-23",
      "localName" => "Día de Castilla y León",
      "name" => "Castile and León Day",
      "countryCode" => "ES",
      "fixed" => true,
      "global" => false,
      "counties" => [ "ES-CL" ],
      "launchYear" => 1986,
      "types" => [ "Public" ]
    }

    holiday = Holiday.from_api(payload)

    assert_equal false, holiday.global
    assert_equal [ "ES-CL" ], holiday.counties
    assert_equal 1986, holiday.launch_year
  end
end
