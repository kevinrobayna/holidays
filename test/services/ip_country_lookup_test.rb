require "test_helper"

class IpCountryLookupTest < ActiveSupport::TestCase
  class FakeReader
    attr_reader :calls

    def initialize(mappings = {})
      @mappings = mappings
      @calls = []
    end

    def country(ip)
      @calls << ip
      iso = @mappings[ip]
      raise MaxMind::GeoIP2::AddressNotFoundError, "no record for #{ip}" if iso.nil?
      country_record = Struct.new(:iso_code).new(iso)
      Struct.new(:country).new(country_record)
    end
  end

  test "returns iso_code from reader for a public IP" do
    reader = FakeReader.new("81.2.69.142" => "GB")
    assert_equal "GB", IpCountryLookup.new(reader: reader).call("81.2.69.142")
  end

  test "returns nil for blank IP without consulting reader" do
    reader = FakeReader.new
    assert_nil IpCountryLookup.new(reader: reader).call(nil)
    assert_nil IpCountryLookup.new(reader: reader).call("")
    assert_empty reader.calls
  end

  test "returns nil for IPv4 loopback without consulting reader" do
    reader = FakeReader.new
    assert_nil IpCountryLookup.new(reader: reader).call("127.0.0.1")
    assert_empty reader.calls
  end

  test "returns nil for IPv6 loopback without consulting reader" do
    reader = FakeReader.new
    assert_nil IpCountryLookup.new(reader: reader).call("::1")
    assert_empty reader.calls
  end

  test "returns nil for private IPv4 ranges without consulting reader" do
    reader = FakeReader.new
    %w[10.0.0.1 192.168.1.1 172.16.0.5].each do |ip|
      assert_nil IpCountryLookup.new(reader: reader).call(ip), "expected #{ip} to be skipped as private"
    end
    assert_empty reader.calls
  end

  test "returns nil for malformed IP" do
    reader = FakeReader.new
    assert_nil IpCountryLookup.new(reader: reader).call("not-an-ip")
    assert_empty reader.calls
  end

  test "returns nil when reader has no record for the IP" do
    reader = FakeReader.new
    assert_nil IpCountryLookup.new(reader: reader).call("1.1.1.1")
  end

  test "returns nil when reader is nil (database missing)" do
    assert_nil IpCountryLookup.new(reader: nil).call("8.8.8.8")
  end

  test "build_reader returns nil for blank path" do
    assert_nil IpCountryLookup.build_reader(nil)
    assert_nil IpCountryLookup.build_reader("")
  end

  test "build_reader returns nil when file is missing" do
    missing = Rails.root.join("tmp", "definitely-not-here-#{SecureRandom.hex(4)}.mmdb").to_s
    assert_nil IpCountryLookup.build_reader(missing)
  end

  test "initializer wires the GeoIP database path into Rails config" do
    assert_kind_of String, Rails.application.config.x.geoip_db_path
    assert_predicate Rails.application.config.x.geoip_db_path, :present?
  end
end
