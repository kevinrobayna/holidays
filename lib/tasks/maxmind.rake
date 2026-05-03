namespace :maxmind do
  desc "Download MaxMind GeoLite2-Country database into vendor/maxmind/"
  task download: :environment do
    require "net/http"
    require "tempfile"
    require "rubygems/package"
    require "zlib"

    target = Rails.application.config.x.maxmind_db_path
    FRESH_FOR = 30 * 24 * 60 * 60 # 30 days in seconds

    if File.exist?(target) && (Time.now - File.mtime(target)) < FRESH_FOR
      puts "[maxmind:download] #{target} is <30d old, skipping. Delete the file to force a refresh."
      next
    end

    license_key = Rails.application.credentials.dig(:maxmind, :license_key) || ENV["MAXMIND_LICENSE_KEY"]
    if license_key.to_s.strip.empty?
      warn "[maxmind:download] no license key configured. Set credentials.maxmind.license_key or MAXMIND_LICENSE_KEY env var. Skipping."
      next
    end

    url = URI("https://download.maxmind.com/app/geoip_download?edition_id=GeoLite2-Country&license_key=#{license_key}&suffix=tar.gz")

    FileUtils.mkdir_p(File.dirname(target))

    Tempfile.open([ "geolite2-country", ".tar.gz" ], binmode: true) do |tmp|
      Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
        http.request(Net::HTTP::Get.new(url.request_uri)) do |response|
          response.value
          response.read_body { |chunk| tmp.write(chunk) }
        end
      end
      tmp.flush
      tmp.rewind

      extracted = false
      Zlib::GzipReader.wrap(tmp) do |gz|
        Gem::Package::TarReader.new(gz).each do |entry|
          next unless entry.full_name.end_with?("GeoLite2-Country.mmdb")
          File.binwrite(target, entry.read)
          extracted = true
          break
        end
      end

      abort "[maxmind:download] download succeeded but archive did not contain GeoLite2-Country.mmdb" unless extracted
    end

    puts "[maxmind:download] wrote #{target}"
  end
end
