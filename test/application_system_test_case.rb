require "test_helper"
require "axe/core"
require "axe/api/run"

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [ 1400, 1400 ]

  def assert_accessible(context = nil)
    run = Axe::API::Run.new
    run.within(context) if context
    audit = Axe::Core.new(page).call(run)
    assert audit.passed?, audit.failure_message
  end
end
