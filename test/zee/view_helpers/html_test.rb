# frozen_string_literal: true

require "test_helper"

class HTMLTest < Minitest::Test
  let(:helpers) do
    mod = Module.new do
      attr_accessor :request

      include Zee::ViewHelpers::OutputSafety
      include Zee::ViewHelpers::HTML
      include Zee::ViewHelpers::Capture
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

  test "renders html tag" do
    html = helpers.content_tag(:p, "hello!").to_s

    assert_equal "<p>hello!</p>", html
  end

  test "renders html tag with block" do
    html = render <<~ERB
      <%= content_tag :p do %>
        hello!
      <% end %>
    ERB

    assert_equal "<p>\n  hello!\n</p>", html.to_s
  end

  test "renders html tag with attributes" do
    html = render <<~ERB
      <%= content_tag :header, id: "main-header" do %>
        hello!
      <% end %>
    ERB

    assert_equal %[<header id="main-header">\n  hello!\n</header>], html.to_s
  end

  test "builds css classes" do
    assert_equal "foo bar", helpers.class_names({foo: true, bar: true})
    assert_equal "foo bar", helpers.class_names("foo", "bar")
    assert_equal "foo bar", helpers.class_names("foo", nil, "bar")
    assert_equal "foo bar", helpers.class_names("foo", false, "bar")
    assert_equal "foo bar", helpers.class_names("foo", "", "bar")
    assert_equal "foo bar", helpers.class_names("foo", ["", "bar"])
    assert_equal "foo bar", helpers.class_names("foo", ["", "bar", "foo"])
    assert_equal "foo bar", helpers.class_names("foo", bar: true)
    assert_equal "foo bar", helpers.class_names("foo", bar: true, baz: false)
  end

  test "builds attributes" do
    assert_equal %[ class="foo bar"], helpers.html_attrs(class: "foo bar")
    assert_equal %[ title="&lt;3"], helpers.html_attrs(title: "<3")
    assert_equal %[ title="hello" id="up"],
                 helpers.html_attrs(title: "hello", id: "up")
    assert_equal %[ id="profile" data-user-id="1"],
                 helpers.html_attrs(id: "profile", data: {user_id: 1})
    assert_equal %[ title="between &quot;quotes&quot;"],
                 helpers.html_attrs(title: %[between "quotes"])
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
