# frozen_string_literal: true

require "test_helper"

class AuthenticationTest < Zee::Test::Integration
  include Capybara::DSL

  setup do
    app_class = Class.new(Zee::App)
    app = app_class.new
    Zee.app = app

    app.root =
      Pathname(File.expand_path(File.join("./test/fixtures/auth")))

    app.routes do
      root to: "home#show"
      get "login", to: "login#new", as: "login"
      post "login", to: "login#create"
      get "dashboard", to: "dashboard#show", as: :dashboard
      get "metrics", to: "metrics#show", as: :metrics
    end

    app.config do
      set :session_options, domain: "localhost", secure: false
    end

    app.initialize!
  end

  setup { Capybara.default_host = "http://localhost" }
  teardown { Zee.app.loader.unregister }

  test "logs in a user" do
    visit "/"
    click_link "Log in"

    fill_in "Email", with: "me@example.com"
    click_button "Log in"

    assert_current_path "/dashboard"
    assert_includes page.body, "your email is me@example.com"
  end

  test "redirects logged user" do
    visit "/"
    click_link "Log in"

    fill_in "Email", with: "me@example.com"
    click_button "Log in"

    visit "/login"

    assert_current_path "/dashboard"
  end

  test "redirects unlogged user to login page" do
    visit "/dashboard"

    assert_current_path "/login"
  end

  test "renders unauthorized page" do
    visit "/"
    click_link "Log in"

    fill_in "Email", with: "me@example.com"
    click_button "Log in"

    assert_current_path "/dashboard"

    visit "/metrics"

    assert_current_path "/metrics"
    assert_includes page.body, "Unauthorized"
  end

  test "allows authorized user" do
    visit "/"
    click_link "Log in"

    fill_in "Email", with: "admin@example.com"
    click_button "Log in"

    visit "/metrics"

    assert_current_path "/metrics"
    assert_includes page.body, "metrics"
  end

  test "redirects to url after logging in" do
    visit "/metrics"

    fill_in "Email", with: "admin@example.com"
    click_button "Log in"

    assert_current_path "/metrics"
  end
end
