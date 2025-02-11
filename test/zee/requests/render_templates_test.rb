# frozen_string_literal: true

require "test_helper"

class RenderTemplatesTest < Minitest::Test
  include Rack::Test::Methods

  def app
    SampleApp
  end

  test "renders root" do
    get "/"

    assert last_response.ok?
    assert_includes last_response.body,
                    "sample_app:app/views/pages/home.html.erb"
    assert_includes last_response.content_type, "text/html"
  end

  test "handles missing template" do
    get "/missing-template"

    assert_equal 500, last_response.status
    assert_includes last_response.body, "Zee::MissingTemplateError"
  end

  test "renders template with locals" do
    get "/hello"

    assert last_response.ok?
    assert_includes last_response.body, "Hello, World!"
    assert_includes last_response.content_type, "text/html"
  end

  test "renders page not found" do
    get "/not-found"

    assert last_response.not_found?
    assert_includes last_response.body, "404 Not Found"
    assert_includes last_response.content_type, "text/plain"
  end
end
