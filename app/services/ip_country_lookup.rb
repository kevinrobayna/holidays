require "ipaddr"

class IpCountryLookup
  def self.call(ip)
    new.call(ip)
  end

  def self.build_reader(path)
    return nil if path.blank?
    return nil unless File.exist?(path)
    MaxMind::GeoIP2::Reader.new(database: path)
  rescue Errno::ENOENT, MaxMind::DB::InvalidDatabaseError
    nil
  end

  def initialize(reader: Rails.configuration.x.geoip_reader)
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
