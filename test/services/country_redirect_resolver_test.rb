require "test_helper"

class CountryRedirectResolverTest < ActiveSupport::TestCase
  class FakeLookup
    attr_reader :calls

    def initialize(result = nil, error: nil)
      @result = result
      @error = error
      @calls = []
    end

    def call(ip)
      @calls << ip
      raise @error if @error
      @result
    end
  end

  class FakeFetcher
    attr_reader :calls

    def initialize(countries = [], error: nil)
      @countries = countries
      @error = error
      @calls = 0
    end

    def call
      @calls += 1
      raise @error if @error
      @countries
    end
  end

  SUPPORTED = [
    Country.new(country_code: "AD", name: "Andorra"),
    Country.new(country_code: "ES", name: "Spain"),
    Country.new(country_code: "GB", name: "United Kingdom")
  ].freeze

  test "matched: lookup returns supported country code" do
    lookup = FakeLookup.new("ES")
    fetcher = FakeFetcher.new(SUPPORTED)

    result = CountryRedirectResolver.new(lookup: lookup, fetcher: fetcher).call(ip: "203.0.113.1")

    assert_equal "ES", result.country_code
    assert_equal :matched, result.reason
    assert_equal [ "203.0.113.1" ], lookup.calls
    assert_equal 1, fetcher.calls
  end

  test "unsupported: lookup returns a country code we don't support" do
    lookup = FakeLookup.new("XX")
    fetcher = FakeFetcher.new(SUPPORTED)

    result = CountryRedirectResolver.new(lookup: lookup, fetcher: fetcher).call(ip: "203.0.113.2")

    assert_nil result.country_code
    assert_equal :unsupported, result.reason
  end

  test "unknown_ip: lookup returns nil and fetcher is not invoked" do
    lookup = FakeLookup.new(nil)
    fetcher = FakeFetcher.new(SUPPORTED)

    result = CountryRedirectResolver.new(lookup: lookup, fetcher: fetcher).call(ip: "127.0.0.1")

    assert_nil result.country_code
    assert_equal :unknown_ip, result.reason
    assert_equal 0, fetcher.calls, "fetcher must be skipped when no IP match"
  end

  test "error: fetcher raises is caught and returns error result" do
    lookup = FakeLookup.new("ES")
    fetcher = FakeFetcher.new(error: NagerDateClient::Error.new("upstream down"))

    result = CountryRedirectResolver.new(lookup: lookup, fetcher: fetcher).call(ip: "203.0.113.3")

    assert_nil result.country_code
    assert_equal :error, result.reason
  end

  test "error: lookup raises an unexpected error is caught" do
    lookup = FakeLookup.new(error: RuntimeError.new("boom"))
    fetcher = FakeFetcher.new(SUPPORTED)

    result = CountryRedirectResolver.new(lookup: lookup, fetcher: fetcher).call(ip: "203.0.113.4")

    assert_nil result.country_code
    assert_equal :error, result.reason
    assert_equal 0, fetcher.calls
  end
end
