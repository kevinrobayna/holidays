require "test_helper"

class CountriesControllerTest < ActionDispatch::IntegrationTest
  test "GET /:country_code renders the country code (lowercase input)" do
    get "/es"

    assert_response :ok
    assert_includes response.body, "ES"
  end

  test "GET /:country_code accepts uppercase and normalizes" do
    get "/ES"

    assert_response :ok
    assert_includes response.body, "ES"
  end

  test "country_path helper produces lowercase 2-letter path" do
    assert_equal "/es", Rails.application.routes.url_helpers.country_path(country_code: "es")
  end

  test "GET /:country_code returns 404 for non-2-letter input" do
    get "/abc"
    assert_response :not_found

    get "/a"
    assert_response :not_found
  end

  test "GET /:country_code returns 404 for digits" do
    get "/12"
    assert_response :not_found
  end
end
