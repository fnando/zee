# frozen_string_literal: true

require "test_helper"

class StaticTest < Minitest::Test
  include Rack::Test::Methods

  def app
    Rack::Builder.app do
      use Zee::Middleware::Static
      run ->(_env) { [404, {"content-type" => "text/html"}, ["Not Found"]] }
    end
  end

  test "makes GET request to file" do
    Dir.chdir("test/fixtures/sample_app") do
      get "/favicon.ico"
    end

    assert last_response.ok?
    assert_equal "image/vnd.microsoft.icon",
                 last_response.headers["content-type"]
  end

  test "makes HEAD request to file" do
    Dir.chdir("test/fixtures/sample_app") do
      head "/favicon.ico"
    end

    assert last_response.ok?
    assert_equal "image/vnd.microsoft.icon",
                 last_response.headers["content-type"]
  end

  test "skips other request methods" do
    Dir.chdir("test/fixtures/sample_app") do
      post "/favicon.ico"
    end

    assert last_response.not_found?
  end
end
