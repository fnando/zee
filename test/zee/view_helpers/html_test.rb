# frozen_string_literal: true

require "test_helper"

class HTMLTest < Minitest::Test
  include Zee::Test::Assertions::HTML

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
    request = Zee::Request.new(Rack::MockRequest.env_for("/"))
    request.env[Zee::ZEE_CSP_NONCE] = "abc"

    template = <<~ERB
      <%= javascript_tag do %>
        console.log('Hello, World!')
      <% end %>
    ERB

    html = render(template, request:)

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

    assert_selector html, "style", text: /body \{ color: red; \}/
  end

  test "renders style tag with nonce" do
    request = Zee::Request.new(Rack::MockRequest.env_for("/"))
    request.env[Zee::ZEE_CSP_NONCE] = "abc"

    template = <<~ERB
      <%= style_tag do %>
        body { color: red; }
      <% end %>
    ERB

    html = render(template, request:)

    assert_selector html, "style[nonce=abc]", text: /body \{ color: red; \}/
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

    assert_selector html, "p", text: /hello!/
  end

  test "renders html tag with attributes" do
    html = render <<~ERB
      <%= content_tag :header, id: "main-header" do %>
        hello!
      <% end %>
    ERB

    assert_selector html, "header#main-header", text: /hello!/
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
    assert_equal %[ role="tab" aria-selected="true"],
                 helpers.html_attrs(role: "tab", aria: {selected: true})
    assert_equal %[ title="between &quot;quotes&quot;"],
                 helpers.html_attrs(title: %[between "quotes"])
    assert_equal "", helpers.html_attrs(selected: false)
    assert_equal "", helpers.html_attrs(id: false)
    assert_equal "", helpers.html_attrs(class: "")
  end

  test "renders open tag" do
    assert_equal "<br>", helpers.tag(:br).to_s
  end

  test "renders bool attributes" do
    assert_equal "<button disabled>Button</button>",
                 helpers.tag(:button, "Button", disabled: true).to_s
  end
end
