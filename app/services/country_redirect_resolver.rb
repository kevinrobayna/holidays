class CountryRedirectResolver
  Result = Data.define(:country_code, :reason)

  def self.call(ip:)
    new.call(ip: ip)
  end

  def initialize(lookup: IpCountryLookup, fetcher: CountryFetcher)
    @lookup = lookup
    @fetcher = fetcher
  end

  def call(ip:)
    code = @lookup.call(ip)
    return Result.new(country_code: nil, reason: :unknown_ip) unless code

    if @fetcher.call.any? { |country| country.country_code == code }
      Result.new(country_code: code, reason: :matched)
    else
      Result.new(country_code: nil, reason: :unsupported)
    end
  rescue StandardError => e
    Rails.logger.warn("CountryRedirectResolver failed: #{e.class}: #{e.message}")
    Result.new(country_code: nil, reason: :error)
  end
end
