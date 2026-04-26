require "test_helper"

class HolidayFetcherTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :calls

    def initialize(payloads = {}, error: nil)
      @payloads = payloads
      @error = error
      @calls = []
    end

    def public_holidays(year:, country_code:)
      @calls << { year: year, country_code: country_code }
      raise @error if @error
      @payloads.fetch([ year, country_code ], [])
    end
  end

  ES_2026_PAYLOAD = [
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

  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "returns array of Holiday value objects parsed from API payload" do
    client = FakeClient.new({ [ 2026, "ES" ] => ES_2026_PAYLOAD })

    result = HolidayFetcher.new(client: client).call(country_code: "ES", year: 2026)

    assert_equal 1, result.size
    holiday = result.first
    assert_kind_of Holiday, holiday
    assert_equal Date.new(2026, 1, 1), holiday.date
    assert_equal "Año Nuevo", holiday.local_name
    assert_equal "ES", holiday.country_code
  end

  test "second call within TTL is served from cache (client invoked once)" do
    client = FakeClient.new({ [ 2026, "ES" ] => ES_2026_PAYLOAD })
    fetcher = HolidayFetcher.new(client: client)

    fetcher.call(country_code: "ES", year: 2026)
    fetcher.call(country_code: "ES", year: 2026)

    assert_equal 1, client.calls.size
  end

  test "different countries and years use independent cache entries" do
    client = FakeClient.new({
      [ 2026, "ES" ] => ES_2026_PAYLOAD,
      [ 2026, "GB" ] => [],
      [ 2027, "ES" ] => []
    })
    fetcher = HolidayFetcher.new(client: client)

    fetcher.call(country_code: "ES", year: 2026)
    fetcher.call(country_code: "GB", year: 2026)
    fetcher.call(country_code: "ES", year: 2027)

    assert_equal 3, client.calls.size
  end

  test "country code is normalised to upcase before caching" do
    client = FakeClient.new({ [ 2026, "ES" ] => ES_2026_PAYLOAD })
    fetcher = HolidayFetcher.new(client: client)

    fetcher.call(country_code: "es", year: 2026)
    fetcher.call(country_code: "ES", year: 2026)
    fetcher.call(country_code: " es ", year: 2026)

    assert_equal 1, client.calls.size
    assert_equal "ES", client.calls.first[:country_code]
  end

  test "raises ArgumentError on invalid country code without calling client" do
    client = FakeClient.new
    fetcher = HolidayFetcher.new(client: client)

    [ nil, "", "E", "ESP", "12", "e1" ].each do |bad|
      assert_raises(ArgumentError, "expected ArgumentError for #{bad.inspect}") do
        fetcher.call(country_code: bad, year: 2026)
      end
    end

    assert_empty client.calls
  end

  test "raises ArgumentError on invalid year without calling client" do
    client = FakeClient.new
    fetcher = HolidayFetcher.new(client: client)

    [ nil, "2026", 1900, 2300, 2026.5 ].each do |bad|
      assert_raises(ArgumentError, "expected ArgumentError for #{bad.inspect}") do
        fetcher.call(country_code: "ES", year: bad)
      end
    end

    assert_empty client.calls
  end

  test "client errors are not cached" do
    failing_client = FakeClient.new(error: NagerDateClient::Error.new("boom"))
    assert_raises(NagerDateClient::Error) do
      HolidayFetcher.new(client: failing_client).call(country_code: "ES", year: 2026)
    end

    succeeding_client = FakeClient.new({ [ 2026, "ES" ] => ES_2026_PAYLOAD })
    result = HolidayFetcher.new(client: succeeding_client).call(country_code: "ES", year: 2026)

    assert_equal 1, succeeding_client.calls.size
    assert_equal 1, result.size
  end

  test "empty list response is cached" do
    client = FakeClient.new({ [ 2026, "ES" ] => [] })
    fetcher = HolidayFetcher.new(client: client)

    assert_equal [], fetcher.call(country_code: "ES", year: 2026)
    assert_equal [], fetcher.call(country_code: "ES", year: 2026)

    assert_equal 1, client.calls.size
  end

  test "class-level call wires up a real NagerDateClient end-to-end" do
    stub_request(:get, "https://date.nager.at/api/v3/PublicHolidays/2026/ES")
      .to_return(status: 200, body: ES_2026_PAYLOAD.to_json, headers: { "Content-Type" => "application/json" })

    result = HolidayFetcher.call(country_code: "ES", year: 2026)

    assert_equal 1, result.size
    assert_equal Date.new(2026, 1, 1), result.first.date
  end
end
