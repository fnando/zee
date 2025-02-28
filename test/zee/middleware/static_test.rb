# frozen_string_literal: true

require "test_helper"

class StaticTest < Zee::RequestTest
  def app
    Rack::Builder.app do
      middleware = Class.new do
        def initialize(app)
          @app = app
        end

        def call(env)
          app = Struct.new(:env).new(Zee::Environment.new(:development))
          Zee.app = app
          @app.call(env)
        end
      end

      use middleware
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

  test "sets cache control header" do
    Dir.chdir("test/fixtures/sample_app") do
      get "/assets/logo.png"
    end

    assert last_response.ok?
    assert_equal "no-store, no-cache, max-age=0, must-revalidate",
                 last_response.headers["cache-control"]
  end

  test "skips other request methods" do
    Dir.chdir("test/fixtures/sample_app") do
      post "/favicon.ico"
    end

    assert last_response.not_found?
  end
end
