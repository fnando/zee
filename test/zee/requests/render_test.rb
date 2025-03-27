# frozen_string_literal: true

require "test_helper"

class RenderTest < Zee::Test::Integration
  setup do
    store_translations :en, zee: {meta: {pages: {home: {title: "My app"}}}}
  end

  test "renders root" do
    get "/"

    assert last_response.ok?
    assert_includes last_response.body,
                    "sample_app:app/views/pages/home.html.erb"
    assert_includes last_response.content_type, "text/html"
  end

  test "renders namespaced routes" do
    get "/admin/posts"

    assert last_response.ok?
    assert_includes last_response.body, "hello from admin"
    assert_includes last_response.content_type, "text/html"
  end

  test "handles missing template" do
    get "/missing-template"

    assert_equal 500, last_response.status
    assert_includes last_response.body, "Zee::Controller::MissingTemplateError"
  end

  test "renders template with instance variables" do
    get "/hello"

    assert last_response.ok?
    assert_includes last_response.body, "Hello, World!"
    assert_includes last_response.content_type, "text/html"
  end

  test "renders page not found" do
    get "/not-found"

    assert last_response.not_found?
    assert_includes last_response.body, "404 Not Found"
    assert_includes last_response.content_type, "text/plain"
  end

  test "renders text" do
    get "/text"

    assert last_response.ok?
    assert_includes last_response.body, "Hello, World!"
    assert_includes last_response.content_type, "text/plain"
  end

  test "renders json" do
    get "/json"

    expected = {"message" => "Hello, World!"}

    assert last_response.ok?
    assert_equal expected, JSON.parse(last_response.body)
    assert_includes last_response.content_type, "application/json"
  end

  test "redirects to page" do
    get "/redirect"

    assert last_response.redirect?
    assert_equal "/", last_response.location
    assert_equal 302, last_response.status
  end

  test "rejects open redirects by default" do
    get "/redirect-error"

    assert last_response.server_error?
    assert_includes last_response.body,
                    "Zee::Controller::UnsafeRedirectError: Unsafe redirect; " \
                    "pass `allow_other_host: true` to redirect anyway."
    assert_nil last_response.location
  end

  test "allows open redirect" do
    get "/redirect-open"

    assert last_response.redirect?
    refute_includes last_response.body, "Zee::Controller::UnsafeRedirectError"
    assert_equal "https://example.com", last_response.location
  end

  test "renders default layout" do
    get "/"

    assert last_response.ok?
    assert_includes last_response.body, "<title>My app</title>"
    assert_includes last_response.content_type, "text/html"
  end

  test "renders controller layout" do
    get "/controller-layout"

    assert last_response.ok?
    assert_includes last_response.body, "<title>My things layout</title>"
    assert_includes last_response.body,
                    "sample_app:app/views/things/show.html.erb"
    assert_includes last_response.content_type, "text/html"
  end

  test "renders custom layout" do
    get "/custom-layout"

    assert last_response.ok?
    assert_includes last_response.body, "<title>My custom layout</title>"
    assert_includes last_response.body,
                    "sample_app:app/views/pages/custom_layout.html.erb"
    assert_includes last_response.content_type, "text/html"
  end

  test "renders no layout" do
    get "/no-layout"

    assert last_response.ok?
    refute_includes last_response.body, "<title>"
    assert_includes last_response.body,
                    "sample_app:app/views/pages/no_layout.html.erb"
    assert_includes last_response.content_type, "text/html"
  end

  test "renders any available template when accepting `*/*`" do
    get "/", {}, "HTTP_ACCEPT" => "*/*"

    assert last_response.ok?
    assert_includes last_response.body, "<title>My app</title>"
    assert_includes last_response.content_type, "text/html"
  end

  test "renders html when no accept header is provided" do
    get "/", {}, "HTTP_ACCEPT" => ""

    assert last_response.ok?
    assert_includes last_response.body, "<title>My app</title>"
    assert_includes last_response.content_type, "text/html"
  end

  test "renders correct mime based on the available template name" do
    get "/feed", {}, "HTTP_ACCEPT" => "*/*"

    assert last_response.ok?
    assert_includes last_response.body,
                    %[<?xml version="1.0" encoding="UTF-8"?>]
    assert_includes last_response.content_type, "application/xml"
  end

  test "renders rack app (lambda)" do
    get "/proc-app"

    assert last_response.ok?
    assert_includes last_response.body, "hello from rack app"
    assert_includes last_response.content_type, "text/html"
  end

  test "renders rack app (class)" do
    get "/class-app"

    assert last_response.ok?
    assert_includes last_response.body, "hello from my app"
    assert_includes last_response.content_type, "text/html"
  end

  test "renders meta tags" do
    get "/"

    assert last_response.ok?
    assert_selector last_response.body, "meta[charset='UTF-8']"
  end

  test "redirects (301)" do
    get "/old"

    assert last_response.redirect?
    assert_equal "/", last_response.location
    assert_equal 301, last_response.status
  end

  test "redirects (302)" do
    get "/found"

    assert last_response.redirect?
    assert_equal "/", last_response.location
    assert_equal 302, last_response.status
  end

  test "redirects (rack app)" do
    get "/redirect-rack-app"

    assert last_response.redirect?
    assert_equal "/", last_response.location
    assert_equal 302, last_response.status
  end
end
