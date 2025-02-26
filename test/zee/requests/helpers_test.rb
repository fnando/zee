# frozen_string_literal: true

require "test_helper"

class HelpersTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Zee.app
  end

  test "includes defined helper modules" do
    assert_includes app.helpers.included_modules, Helpers::I18n
    assert_includes app.helpers.included_modules, Helpers::L10n
  end

  test "helpers include url helpers" do
    assert_includes app.helpers.included_modules, app.routes.helpers
  end

  test "renders root" do
    get "/helpers"

    assert_includes last_response.body, "t.name"
    assert_includes last_response.body, "l.date"
    assert_includes last_response.content_type, "text/html"
    assert last_response.ok?
  end
end
