require "test_helper"

class HomeControllerTest < ActionDispatch::IntegrationTest
  Result = CountryRedirectResolver::Result

  def stub_resolver_call(replacement)
    klass = CountryRedirectResolver.singleton_class
    original = klass.instance_method(:call)
    klass.define_method(:call, &replacement)
    yield
  ensure
    klass.define_method(:call, original) if original
  end

  test "redirects to /:country_code when resolver matches a supported country" do
    captured = {}
    replacement = lambda do |**kwargs|
      captured[:kwargs] = kwargs
      Result.new(country_code: "ES", reason: :matched)
    end

    stub_resolver_call(replacement) do
      get "/"
    end

    assert_redirected_to "/es"
    assert_response :found
    assert_kind_of String, captured.dig(:kwargs, :ip)
  end

  test "renders landing page when country is unsupported" do
    stub_resolver_call(->(**) { Result.new(country_code: nil, reason: :unsupported) }) do
      get "/"
    end

    assert_response :ok
    assert_includes response.body, "Pick a country"
  end

  test "renders landing page when IP is unknown" do
    stub_resolver_call(->(**) { Result.new(country_code: nil, reason: :unknown_ip) }) do
      get "/"
    end

    assert_response :ok
  end

  test "renders landing page when resolver errors out" do
    stub_resolver_call(->(**) { Result.new(country_code: nil, reason: :error) }) do
      get "/"
    end

    assert_response :ok
  end

  test "?no_redirect=1 skips resolver entirely" do
    invocations = 0
    replacement = lambda do |**|
      invocations += 1
      Result.new(country_code: "ES", reason: :matched)
    end

    stub_resolver_call(replacement) do
      get "/?no_redirect=1"
    end

    assert_response :ok
    assert_equal 0, invocations, "resolver must not be called when no_redirect=1 is set"
  end
end
