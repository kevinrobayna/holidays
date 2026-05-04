default_db_path = Rails.root.join("vendor/geoip/dbip-country-lite.mmdb").to_s
Rails.application.config.x.geoip_db_path = ENV.fetch("GEOIP_DB_PATH", default_db_path)

Rails.application.config.to_prepare do
  path   = Rails.application.config.x.geoip_db_path
  reader = IpCountryLookup.build_reader(path)
  Rails.application.config.x.geoip_reader = reader

  if reader.nil?
    Rails.logger&.warn("GeoIP DB unavailable at #{path}; IP-based country redirects disabled")
  end
end
