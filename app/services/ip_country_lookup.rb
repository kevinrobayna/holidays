require "ipaddr"

class IpCountryLookup
  def self.call(ip)
    instance.call(ip)
  end

  def self.instance
    @instance ||= new
  end

  def self.reset!
    @instance = nil
  end

  def initialize(reader: Rails.configuration.x.maxmind_reader)
    @reader = reader
  end

  def call(ip)
    return nil if ip.blank? || @reader.nil?
    addr = IPAddr.new(ip)
    return nil if addr.loopback? || addr.private?
    @reader.country(ip).country.iso_code
  rescue IPAddr::InvalidAddressError, MaxMind::GeoIP2::AddressNotFoundError
    nil
  end
end
