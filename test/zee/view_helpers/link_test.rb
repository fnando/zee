# frozen_string_literal: true

require "test_helper"

class HTMLTest < Minitest::Test
  include Zee::Test::Assertions::HTML

  test "renders link" do
    html = render(%[<%= link_to "Home", "/" %>])

    assert_html html, "a[href='/']", text: "Home"
  end

  test "renders link using block" do
    html = render <<~ERB
      <%= link_to "/" do %>
        <span>Home</span>
      <% end %>
    ERB

    assert_html html, "a[href='/']>span", text: "Home"
  end

  test "renders link with target=_blank" do
    html = render <<~ERB
      <%= link_to "Home", "/", blank: true %>
    ERB

    assert_html html, "a[href='/'][target=_blank]", text: "Home"
  end

  test "renders external links" do
    html = render <<~ERB
      <%= link_to "Home", "/", external: true %>
    ERB

    assert_html html,
                "a[href='/'][rel='noreferrer noopener nofollow external']",
                text: "Home"
  end

  test "renders other attributes" do
    html = render <<~ERB
      <%= link_to "Home", "/", class: "link" %>
    ERB

    assert_html html, "a[href='/'][class='link']", text: "Home"
  end
end
