# frozen_string_literal: true

require "test_helper"

class AppTest < Minitest::Test
  setup do
    Zee::ENV_NAMES.each {|name| ENV.delete(name) }
  end

  test "uses ZEE_ENV as the env value" do
    ENV["ZEE_ENV"] = "production"

    assert Zee::App.new.env.production?
  end

  test "uses APP_ENV as the env value" do
    ENV["APP_ENV"] = "production"

    assert Zee::App.new.env.production?
  end

  test "uses RACK_ENV as the env value" do
    ENV["RACK_ENV"] = "production"

    assert Zee::App.new.env.production?
  end

  test "sets config" do
    app = Zee::App.new do
      config do
        optional :one, string, "one"
      end

      config do
        optional :two, string, "two"
      end
    end

    assert_equal "one", app.config.one
    assert_equal "two", app.config.two
  end

  test "reads secrets" do
    Dir.chdir("test/fixtures/sample_app") do
      app = Zee::App.new

      assert_equal "some-api-key", app.secrets.api_key
    end
  end

  test "prevents app from being initialized twice" do
    app = Zee::App.new
    app.initialize!

    assert_raises(Zee::App::AlreadyInitializedError) { app.initialize! }
  end

  test "prevents app from having the environment set after initialization" do
    app = Zee::App.new
    app.initialize!

    assert_raises(Zee::App::AlreadyInitializedError) { app.env = :test }
  end

  test "runs init  blocks" do
    app = Zee::App.new
    called = []
    this = nil

    app.init do
      called << 1
      this = self
    end

    app.init do
      called << 2
    end

    assert_empty called

    app.initialize!

    assert_equal [1, 2], called
    assert_equal app, this
  end

  test "sets configuration based on the environment" do
    build_app = proc do |app_env|
      Zee::App.new do
        self.env = app_env

        config :development do
          set :domain, "example.dev"
        end

        config :production do
          set :domain, "example.com"
        end
      end
    end

    app = build_app.call(:development)

    assert_equal "example.dev", app.config.domain

    app = build_app.call(:production)

    assert_equal "example.com", app.config.domain
  end

  test "sets default middleware stack" do
    ENV["ZEE_ENV"] = "test"
    app = Zee::App.new

    assert_equal 9, app.middleware.to_a.size
  end
end
