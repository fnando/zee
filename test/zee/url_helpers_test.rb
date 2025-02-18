# frozen_string_literal: true

require "test_helper"

class URLHelpersTest < Minitest::Test
  test "defines route helpers" do
    routes = Zee::Routes.new do
      root to: "home#index"
      get "posts/:id", to: "posts#show", as: :post
      get "categories(/:category)", to: "categories#show", as: :category
      get "(/:locale)/tags(/:tag)",
          to: "tags#show",
          as: :tag
    end

    helpers = Object.new.extend(routes.helpers)

    assert_respond_to helpers, :root_path
    assert_equal "/", helpers.root_path

    assert_respond_to helpers, :post_path
    assert_equal "/posts/1", helpers.post_path(1)

    assert_respond_to helpers, :category_path
    assert_equal "/categories", helpers.category_path
    assert_equal "/categories/ruby", helpers.category_path("ruby")

    assert_respond_to helpers, :tag_path
    assert_equal "/tags", helpers.tag_path
    assert_equal "/en/tags", helpers.tag_path("en")
    assert_equal "/en/tags/ruby", helpers.tag_path("en", "ruby")
    assert_equal "/tags/ruby", helpers.tag_path("", "ruby")
    assert_equal "/tags/ruby", helpers.tag_path(nil, "ruby")

    assert_equal "/?a=1", helpers.root_path(a: 1)
    assert_equal "/posts/1?a=1", helpers.post_path(1, a: 1)

    assert_equal "//example.com/?a=1",
                 helpers.root_path(a: 1, host: "example.com")
    assert_equal "https://example.com/?a=1",
                 helpers.root_path(a: 1, host: "example.com", protocol: :https)
    assert_equal "https://example.com/?a=1#top",
                 helpers.root_path(a: 1, host: "example.com",
                                   protocol: :https,
                                   anchor: "top")
  end

  test "raises when using url without setting a host" do
    routes = Zee::Routes.new { root to: "pages#home" }
    helpers = Object.new.extend(routes.helpers)

    error = assert_raises(ArgumentError) { helpers.root_url }

    assert_equal "Please provide the :host parameter, " \
                 "set default_url_options[:host]",
                 error.message
  end

  test "uses default_url_options" do
    routes = Zee::Routes.new(host: "example.com", protocol: "https") do
      root to: "pages#home"
    end
    helpers = Object.new.extend(routes.helpers)

    assert_equal "https://example.com/", helpers.root_url
  end
end
