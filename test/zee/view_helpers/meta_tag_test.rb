# frozen_string_literal: true

require "test_helper"

class MetaTagTest < Minitest::Test
  include Zee::Test::Assertions::HTML

  let(:env) { Rack::MockRequest.env_for("/").merge(Zee::RACK_SESSION => {}) }
  let(:request) { Zee::Request.new(env) }

  test "renders csp meta tag" do
    request.env[Zee::ZEE_CSP_NONCE] = "abc"
    html = render(%[<%= csp_meta_tag %>], request:)

    assert_selector html, "meta[name=csp-nonce][content=abc]"
  end
end
