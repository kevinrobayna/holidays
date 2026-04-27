Holiday = Data.define(
  :date,
  :local_name,
  :name,
  :country_code,
  :fixed,
  :global,
  :counties,
  :launch_year,
  :types
) do
  def self.from_api(payload)
    new(
      date: Date.parse(payload.fetch("date")),
      local_name: payload.fetch("localName"),
      name: payload.fetch("name"),
      country_code: payload.fetch("countryCode"),
      fixed: payload["fixed"],
      global: payload["global"],
      counties: payload["counties"],
      launch_year: payload["launchYear"],
      types: Array(payload["types"])
    )
  end
end
