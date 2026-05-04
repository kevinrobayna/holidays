namespace :geoip do
  desc "Download DB-IP Lite Country (.mmdb) into the configured GeoIP path"
  task download: :environment do
    require "net/http"
    require "tempfile"
    require "zlib"

    target = Rails.application.config.x.geoip_db_path
    fresh_for = 30 * 24 * 60 * 60 # 30 days in seconds

    if File.exist?(target) && (Time.now - File.mtime(target)) < fresh_for
      puts "[geoip:download] #{target} is <30d old, skipping. Delete the file to force a refresh."
      next
    end

    FileUtils.mkdir_p(File.dirname(target))

    today = Date.current
    candidates = [ today, today.prev_month, today.prev_month(2) ].map { |d| d.strftime("%Y-%m") }

    success = false
    last_error = nil

    candidates.each do |yyyy_mm|
      url = URI("https://download.db-ip.com/free/dbip-country-lite-#{yyyy_mm}.mmdb.gz")
      begin
        Tempfile.open([ "dbip-country-lite", ".mmdb.gz" ], binmode: true) do |tmp|
          Net::HTTP.start(url.host, url.port, use_ssl: true) do |http|
            http.request(Net::HTTP::Get.new(url.request_uri)) do |response|
              response.value
              response.read_body { |chunk| tmp.write(chunk) }
            end
          end
          tmp.flush
          tmp.rewind

          Zlib::GzipReader.wrap(tmp) { |gz| File.binwrite(target, gz.read) }
        end
        puts "[geoip:download] wrote #{target} (DB-IP Lite #{yyyy_mm})"
        success = true
        break
      rescue StandardError => e
        last_error = e
        warn "[geoip:download] #{yyyy_mm} not available (#{e.class}: #{e.message}); trying older snapshot"
      end
    end

    abort "[geoip:download] no DB-IP snapshot could be downloaded. Last error: #{last_error&.message}" unless success
  end
end
