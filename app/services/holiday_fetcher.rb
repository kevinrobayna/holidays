class HolidayFetcher
  CACHE_TTL = 1.hour
  CACHE_NAMESPACE = "holiday_fetcher/v1".freeze
  COUNTRY_CODE_REGEX = /\A[A-Z]{2}\z/
  YEAR_RANGE = 1974..2200 # Nager.Date supports holidays from the mid-70s onward

  def self.call(**kwargs)
    new.call(**kwargs)
  end

  def initialize(client: NagerDateClient.new)
    @client = client
  end

  def call(country_code:, year:)
    normalized_code = normalize_country_code(country_code)
    validate!(normalized_code, year)

    Rails.cache.fetch(cache_key(normalized_code, year), expires_in: CACHE_TTL) do
      fetch_and_map(normalized_code, year)
    end
  end

  private

  def fetch_and_map(country_code, year)
    @client.public_holidays(year: year, country_code: country_code).map { |payload| Holiday.from_api(payload) }
  end

  def normalize_country_code(country_code)
    country_code.to_s.strip.upcase
  end

  def validate!(country_code, year)
    unless country_code.match?(COUNTRY_CODE_REGEX)
      raise ArgumentError, "country_code must be a 2-letter ISO 3166-1 alpha-2 code, got #{country_code.inspect}"
    end

    unless year.is_a?(Integer) && YEAR_RANGE.cover?(year)
      raise ArgumentError, "year must be an Integer in #{YEAR_RANGE}, got #{year.inspect}"
    end
  end

  def cache_key(country_code, year)
    "#{CACHE_NAMESPACE}/#{country_code}/#{year}"
  end
end
