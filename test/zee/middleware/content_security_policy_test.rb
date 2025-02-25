# frozen_string_literal: true

require "test_helper"

class ContentSecurityPolicyTest < Minitest::Test
  test "includes nonce" do
    SecureRandom.expects(:hex).with(32).returns("abc")

    app = Rack::Builder.app do
      use Zee::Middleware::ContentSecurityPolicy
      run ->(_env) { [200, {"content-type" => "text/html"}, []] }
    end

    env = Rack::MockRequest.env_for("/")

    _, headers, _ = app.call(env)

    assert_includes headers["content-security-policy"], "'nonce-abc'"
  end
end
