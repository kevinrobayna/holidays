require "faraday"
require "faraday/retry"

class NagerDateClient
  class Error < StandardError; end

  BASE_URL = "https://date.nager.at".freeze
  RETRY_EXCEPTIONS = (
    Faraday::Retry::Middleware::DEFAULT_EXCEPTIONS + [ Faraday::ServerError, Faraday::TooManyRequestsError ]
  ).freeze

  def initialize(connection: nil)
    @connection = connection || build_connection
  end

  def public_holidays(year:, country_code:)
    get("/api/v3/PublicHolidays/#{year}/#{country_code}")
  end

  def available_countries
    get("/api/v3/AvailableCountries")
  end

  private

  def get(path)
    response = @connection.get(path)
    response.body
  rescue Faraday::Error => e
    raise Error, "Nager.Date request failed: #{e.message}"
  end

  def build_connection
    Faraday.new(url: BASE_URL) do |conn|
      conn.request :retry,
        max: 2,
        interval: 0.2,
        backoff_factor: 2,
        exceptions: RETRY_EXCEPTIONS,
        methods: [ :get ]
      conn.request :json
      conn.response :json, content_type: /\bjson$/
      conn.response :raise_error
      conn.options.open_timeout = 2
      conn.options.timeout = 5
    end
  end
end
