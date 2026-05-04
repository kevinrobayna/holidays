class CountriesController < ApplicationController
  def show
    @country_code = params[:country_code].to_s.upcase
  end
end
