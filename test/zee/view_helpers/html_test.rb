# frozen_string_literal: true

require "test_helper"

class HTMLTest < Minitest::Test
  let(:helpers) do
    mod = Module.new do
      attr_accessor :request

      include Zee::ViewHelpers::HTML
    end

    Object.new.extend(mod).tap do |helpers|
      helpers.request = Zee::Request.new(Rack::MockRequest.env_for("/"))
    end
  end

  test "renders javascript tag" do
    html = render(%[<%= javascript_tag("console.log('Hello, World!')") %>])

    assert_equal "<script>console.log('Hello, World!')</script>", html.to_s
  end

  test "renders javascript tag using block" do
    html = render <<~ERB
      <%= javascript_tag do %>
        console.log('Hello, World!')
      <% end %>
    ERB

    assert_equal "<script>\n  console.log('Hello, World!')\n</script>",
                 html.to_s
  end

  test "renders javascript tag with nonce" do
    helpers.request.env[Zee::ZEE_CSP_NONCE] = "abc"

    html = render <<~ERB
      <%= javascript_tag do %>
        console.log('Hello, World!')
      <% end %>
    ERB

    assert_equal "<script nonce=\"abc\">\n  console.log('Hello, World!')\n" \
                 "</script>",
                 html.to_s
  end

  test "renders style tag" do
    html = render(%[<%= style_tag("body { color: red; }") %>])

    assert_equal "<style>body { color: red; }</style>", html.to_s
  end

  test "renders style tag using block" do
    html = render <<~ERB
      <%= style_tag do %>
        body { color: red; }
      <% end %>
    ERB

    assert_equal "<style>\n  body { color: red; }\n</style>",
                 html.to_s
  end

  test "renders style tag with nonce" do
    helpers.request.env[Zee::ZEE_CSP_NONCE] = "abc"

    html = render <<~ERB
      <%= style_tag do %>
        body { color: red; }
      <% end %>
    ERB

    assert_equal "<style nonce=\"abc\">\n  body { color: red; }\n</style>",
                 html.to_s
  end

  def render(template)
    erb = Tilt.new(
      "erb",
      engine_class: Erubi::CaptureBlockEngine,
      freeze_template_literals: false,
      escape: true,
      bufval: "::Zee::SafeBuffer::Erubi.new",
      bufvar: "@output_buffer"
    ) { template }

    erb.render(helpers)
  end
end
