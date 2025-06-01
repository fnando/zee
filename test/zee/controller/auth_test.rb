# frozen_string_literal: true

require "test_helper"

class AuthenticationTest < Zee::Test::System
  def app
    AuthApp
  end

  setup do
    Zee.app = AuthApp
    Zee.app.root = Pathname.pwd.join("test/fixtures/auth")
    Zee.app.view_paths.clear
    Zee.app.view_paths << Zee.app.root.join("app/views")

    Capybara.current_driver = :rack_test
    Capybara.default_host = "http://localhost"
    Capybara.app_host = "http://localhost"
  end

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
