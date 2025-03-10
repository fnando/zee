# frozen_string_literal: true

require "test_helper"

class MetaTagTest < Minitest::Test
  include Zee::Test::Assertions::HTML

  let(:request) do
    Zee::Request.new(
      Rack::MockRequest.env_for("/")
        .merge(
          Zee::ZEE_CSP_NONCE => "abc",
          "rack.session" => {Zee::CSRF_SESSION_KEY => "def"}
        )
    )
  end

  test "renders csp meta tag" do
    html = render(%[<%= csp_meta_tag %>], request:)

    assert_selector html, "meta[name=csp-nonce][content=abc]"
  end

  test "renders csrf meta tags" do
    html = render(%[<%= csrf_meta_tag %>], request:)

    assert_selector html, "meta[name=csrf-param][content=_authenticity_token]"
    assert_selector html, "meta[name=csrf-token][content=def]"
  end
end
