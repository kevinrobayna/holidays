class HomeController < ApplicationController
  def index
    return if params[:no_redirect] == "1"

    result = CountryRedirectResolver.call(ip: request.remote_ip)
    return unless result.country_code

    redirect_to country_path(country_code: result.country_code.downcase)
  end
end
