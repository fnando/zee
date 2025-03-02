# frozen_string_literal: true

require "test_helper"

class SafeBufferTest < Minitest::Test
  include Zee::Test::Assertions::HTML

  let(:string) { Zee::SafeBuffer.new }

  test "inspects buffer" do
    assert_equal %["hello"], Zee::SafeBuffer.new("hello").inspect
  end

  test "compares to strings" do
    assert_operator(string, :==, "") # rubocop:disable Minitest/AssertEqual
    assert_operator(string, :eql?, "")
  end

  test "escapes raw strings" do
    string << "<script>"

    assert_equal "&lt;script&gt;", string.to_s
  end

  test "concats raw strings" do
    other = string.concat("<script>")

    assert_equal "&lt;script&gt;", other.to_s
    refute_same string, other
  end

  test "adds raw strings" do
    string = Zee::SafeBuffer.new
    string += "<script>"

    assert_equal "&lt;script&gt;", string.to_s
  end

  test "returns raw strings" do
    string << "<script>"

    assert_kind_of Zee::SafeBuffer, string.raw
    assert_equal "<script>", string.raw.to_s
  end

  test "keeps safe strings as it is" do
    string << Zee::SafeBuffer.new("<script>")

    assert_equal "<script>", string.to_s
  end

  test "does not mess with regular strings" do
    string << "hello"

    assert_equal "hello", string.to_s
  end

  test "works with primitives" do
    string << 1
    string << ":"
    string << true

    assert_equal "1:true", string.to_s
  end

  test "works with nested buffers" do
    string << "<script>"
    string << Zee::SafeBuffer.new("<script>")

    assert_equal "&lt;script&gt;<script>", string.to_s
  end

  test "works with no output in erb context" do
    File.write "tmp/template.erb", <<~ERB
      Hello <3
    ERB
    html = Zee.app.render_template("tmp/template.erb")

    assert_equal "Hello <3", html.to_s.strip
  end

  test "works with flat buffers in erb context" do
    File.write "tmp/template.erb", <<~ERB
      <%= content_tag :h1, "Hello <3" %>
    ERB
    html = Zee.app.render_template("tmp/template.erb")

    assert_selector html, "h1", text: /Hello <3/, html: /Hello &lt;3/
  end

  test "works with nested buffers in erb context" do
    File.write "tmp/template.erb", <<~ERB
      <%= content_tag :div do %>
        <%= content_tag :button do %>
          <%= content_tag :span do %>
            Click me <3
          <% end %>
        <% end %>
      <% end %>
    ERB
    html = Zee.app.render_template("tmp/template.erb")

    assert_selector html,
                    "div>button>span",
                    text: /Click me <3/,
                    html: /Click me &lt;3/
  end

  test "returns escaped strings when converting to json" do
    actual = {"message" => "</script><script>alert('PWNED')</script>"}
    string << JSON.dump(actual)

    expected = <<~JSON.strip
      {"message":"\\u003c/script\\u003e\\u003cscript\\u003ealert('PWNED')\\u003c/script\\u003e"}
    JSON

    assert_equal expected, string.to_json
    assert_equal actual, JSON.parse(string.to_json)
  end

  test "escapes html from strings and buffers" do
    string << "<script>"

    assert_equal "&lt;script&gt;", Zee::SafeBuffer.escape_html("<script>")
    assert_equal "&lt;script&gt;", Zee::SafeBuffer.escape_html(string)
  end

  test "escapes json from strings and buffers" do
    actual = {"message" => "</script><script>alert('PWNED')</script>"}
    string << JSON.dump(actual)

    expected = <<~JSON.strip
      {"message":"\\u003c/script\\u003e\\u003cscript\\u003ealert('PWNED')\\u003c/script\\u003e"}
    JSON

    assert_equal expected, Zee::SafeBuffer.escape_json(string.raw)
    assert_equal expected, Zee::SafeBuffer.escape_json(string.raw.to_s)
    assert_equal expected, Zee::SafeBuffer.escape_json(string)
  end
end
