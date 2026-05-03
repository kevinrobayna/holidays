class CountryFetcher
  CACHE_TTL = 1.hour
  CACHE_KEY = "country_fetcher/v1/all".freeze

  def self.call
    new.call
  end

  def initialize(client: NagerDateClient.new)
    @client = client
  end

  def call
    Rails.cache.fetch(CACHE_KEY, expires_in: CACHE_TTL) do
      @client.available_countries.map { |payload| Country.from_api(payload) }
    end
  end
end
