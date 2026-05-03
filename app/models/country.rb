Country = Data.define(:country_code, :name) do
  def self.from_api(payload)
    new(
      country_code: payload.fetch("countryCode"),
      name: payload.fetch("name")
    )
  end
end
