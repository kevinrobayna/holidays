default_db_path = Rails.root.join("vendor/maxmind/GeoLite2-Country.mmdb").to_s
Rails.application.config.x.maxmind_db_path = ENV.fetch("MAXMIND_DB_PATH", default_db_path)

Rails.application.config.to_prepare do
  path   = Rails.application.config.x.maxmind_db_path
  reader = IpCountryLookup.build_reader(path)
  Rails.application.config.x.maxmind_reader = reader

  if reader.nil?
    Rails.logger&.warn("MaxMind DB unavailable at #{path}; IP-based country redirects disabled")
  end
end
