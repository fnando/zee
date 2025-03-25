# frozen_string_literal: true

require "test_helper"

class ContentSecurityPolicyTest < Minitest::Test
  test "includes nonce under default" do
    SecureRandom.expects(:hex).with(16).returns("abc")

    app = Rack::Builder.app do
      use Zee::Middleware::ContentSecurityPolicy, {
        default_src: "'self'",
        img_src: "'self' data:"
      }
      run ->(_env) { [200, {"content-type" => "text/html"}, []] }
    end

    env = Rack::MockRequest.env_for("/")

    _, headers, _ = app.call(env)

    assert_equal "default-src 'self' 'nonce-abc'; img-src 'self' data: " \
                 "'nonce-abc'",
                 headers["content-security-policy"]
  end
end
