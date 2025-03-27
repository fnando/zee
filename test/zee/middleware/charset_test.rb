# frozen_string_literal: true

require "test_helper"

class CharsetTest < Minitest::Test
  test "adds external encoding to content type" do
    app = Rack::Builder.app do
      use Zee::Middleware::Charset
      run ->(_env) { [200, {"content-type" => "text/html"}, []] }
    end

    _, headers, _ = app.call(Rack::MockRequest.env_for("/"))

    assert_equal "text/html; charset=UTF-8", headers["content-type"]
  end

  test "keeps existing encoding" do
    app = Rack::Builder.app do
      use Zee::Middleware::Charset
      callable = lambda {|_env|
        [200, {"content-type" => "text/html; charset=ISO-8859"}, []]
      }
      run callable
    end

    _, headers, _ = app.call(Rack::MockRequest.env_for("/"))

    assert_equal "text/html; charset=ISO-8859", headers["content-type"]
  end
end
