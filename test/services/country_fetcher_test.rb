require "test_helper"

class CountryFetcherTest < ActiveSupport::TestCase
  class FakeClient
    attr_reader :calls

    def initialize(payloads = nil, error: nil)
      @payloads = payloads
      @error = error
      @calls = 0
    end

    def available_countries
      @calls += 1
      raise @error if @error
      @payloads || []
    end
  end

  COUNTRIES_PAYLOAD = [
    { "countryCode" => "AD", "name" => "Andorra" },
    { "countryCode" => "ES", "name" => "Spain" },
    { "countryCode" => "GB", "name" => "United Kingdom" }
  ]

  setup do
    @original_cache = Rails.cache
    Rails.cache = ActiveSupport::Cache::MemoryStore.new
  end

  teardown do
    Rails.cache = @original_cache
  end

  test "returns array of Country value objects parsed from API payload" do
    client = FakeClient.new(COUNTRIES_PAYLOAD)

    result = CountryFetcher.new(client: client).call

    assert_equal 3, result.size
    assert(result.all? { |c| c.is_a?(Country) })
    assert_equal "AD", result.first.country_code
    assert_equal "Andorra", result.first.name
  end

  test "second call within TTL is served from cache (client invoked once)" do
    client = FakeClient.new(COUNTRIES_PAYLOAD)
    fetcher = CountryFetcher.new(client: client)

    fetcher.call
    fetcher.call

    assert_equal 1, client.calls
  end

  test "empty list response is cached" do
    client = FakeClient.new([])
    fetcher = CountryFetcher.new(client: client)

    assert_equal [], fetcher.call
    assert_equal [], fetcher.call

    assert_equal 1, client.calls
  end

  test "client errors are not cached" do
    failing_client = FakeClient.new(error: NagerDateClient::Error.new("boom"))
    assert_raises(NagerDateClient::Error) do
      CountryFetcher.new(client: failing_client).call
    end

    succeeding_client = FakeClient.new(COUNTRIES_PAYLOAD)
    result = CountryFetcher.new(client: succeeding_client).call

    assert_equal 1, succeeding_client.calls
    assert_equal 3, result.size
  end

  test "class-level call wires up a real NagerDateClient end-to-end" do
    stub_request(:get, "https://date.nager.at/api/v3/AvailableCountries")
      .to_return(status: 200, body: COUNTRIES_PAYLOAD.to_json, headers: { "Content-Type" => "application/json" })

    result = CountryFetcher.call

    assert_equal 3, result.size
    assert_equal "Andorra", result.first.name
  end
end
