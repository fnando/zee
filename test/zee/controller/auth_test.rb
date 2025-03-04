# frozen_string_literal: true

require "test_helper"

class AuthenticationTest < Zee::Test::Request
  class App < Zee::App
    include Singleton
  end

  App.instance.root =
    Pathname(File.expand_path(File.join("./test/fixtures/auth")))

  Zee.app = App.instance

  App.instance.routes do
    root to: "auth#index"
    get "login", to: "auth#index", as: "login"
    post "login", to: "auth#index"
  end

  setup { Zee.app = App.instance }
  setup { Zee.app.initialize! unless Zee.app.initialized? }

  test "logs in a user" do
    Dir.chdir(App.instance.root) do
      get "/"

      assert_equal 200, last_response.status
      assert_selector last_response.body, "form"
    end
  end
end
