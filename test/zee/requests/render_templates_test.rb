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
    assert_raises(Zee::MissingTemplateError) { get "/missing-template" }
  end

  test "renders template with locals" do
    get "/hello"

    assert last_response.ok?
    assert_includes last_response.body, "Hello, World!"
    assert_includes last_response.content_type, "text/html"
  end
end
