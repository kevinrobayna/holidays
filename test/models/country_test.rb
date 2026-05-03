require "test_helper"

class CountryTest < ActiveSupport::TestCase
  test "from_api maps Nager payload onto snake_case attributes" do
    payload = { "countryCode" => "ES", "name" => "Spain" }

    country = Country.from_api(payload)

    assert_kind_of Country, country
    assert_equal "ES", country.country_code
    assert_equal "Spain", country.name
  end

  test "from_api raises KeyError when countryCode is missing" do
    assert_raises(KeyError) do
      Country.from_api({ "name" => "Spain" })
    end
  end

  test "from_api raises KeyError when name is missing" do
    assert_raises(KeyError) do
      Country.from_api({ "countryCode" => "ES" })
    end
  end

  test "is value-equal when constructed with the same attributes" do
    a = Country.new(country_code: "ES", name: "Spain")
    b = Country.new(country_code: "ES", name: "Spain")

    assert_equal a, b
  end
end
