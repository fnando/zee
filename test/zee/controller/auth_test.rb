# frozen_string_literal: true

require "test_helper"

class AuthenticationTest < Zee::Test::Integration
  include Capybara::DSL

  class App < Zee::App
    include Singleton
  end

  App.instance.root =
    Pathname(File.expand_path(File.join("./test/fixtures/auth")))

  Zee.app = App.instance

  App.instance.routes do
    root to: "home#show"
    get "login", to: "auth#new", as: "login"
    post "login", to: "auth#create"
    get "dashboard", to: "dashboard#show", as: :dashboard
  end

  setup { Zee.app = App.instance }
  setup { Zee.app.initialize! unless Zee.app.initialized? }

  test "logs in a user" do
    visit "/"
    click_link "Log in"

    fill_in "Email", with: "me@example.com"
    click_button "Log in"

    assert_current_path "/dashboard"
    assert_includes page.body, "your email is me@example.com"
  end

  test "redirects logged user to dashboard" do
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
end
