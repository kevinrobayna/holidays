require "test_helper"

class NagerDateClientTest < ActiveSupport::TestCase
  ENDPOINT = "https://date.nager.at/api/v3/PublicHolidays/2026/ES"

  test "returns parsed array of holidays on success" do
    body = [
      {
        "date" => "2026-01-01",
        "localName" => "Año Nuevo",
        "name" => "New Year's Day",
        "countryCode" => "ES",
        "fixed" => true,
        "global" => true,
        "counties" => nil,
        "launchYear" => nil,
        "types" => [ "Public" ]
      }
    ]
    stub = stub_request(:get, ENDPOINT)
      .to_return(status: 200, body: body.to_json, headers: { "Content-Type" => "application/json" })

    result = NagerDateClient.new.public_holidays(year: 2026, country_code: "ES")

    assert_equal body, result
    assert_requested(stub, times: 1)
  end

  test "retries transient 503 then succeeds" do
    stub = stub_request(:get, ENDPOINT)
      .to_return({ status: 503, body: "" }, { status: 503, body: "" }, { status: 200, body: "[]", headers: { "Content-Type" => "application/json" } })

    result = NagerDateClient.new.public_holidays(year: 2026, country_code: "ES")

    assert_equal [], result
    assert_requested(stub, times: 3)
  end

  test "raises after retries exhausted on persistent 503" do
    stub_request(:get, ENDPOINT).to_return(status: 503, body: "")

    assert_raises(NagerDateClient::Error) do
      NagerDateClient.new.public_holidays(year: 2026, country_code: "ES")
    end
  end

  test "raises immediately on 404 without retrying" do
    stub = stub_request(:get, ENDPOINT).to_return(status: 404, body: "{}", headers: { "Content-Type" => "application/json" })

    assert_raises(NagerDateClient::Error) do
      NagerDateClient.new.public_holidays(year: 2026, country_code: "ES")
    end
    assert_requested(stub, times: 1)
  end
end
