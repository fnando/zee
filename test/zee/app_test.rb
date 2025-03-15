# frozen_string_literal: true

require "test_helper"

class AppTest < Minitest::Test
  setup do
    Zee::ENV_NAMES.each {|name| ENV.delete(name) }
  end

  test "raises when Zee.app is accesed without being set first" do
    Zee.app = nil

    error = assert_raises(Zee::MissingAppError) do
      Zee.app
    end

    assert_equal "No app has been set to Zee.app", error.message
  end

  test "sets root" do
    app = Zee::App.new { root("/tmp") }

    assert_equal "/tmp", app.root.to_s

    app = Zee::App.new { self.root = "/tmp" }

    assert_equal "/tmp", app.root.to_s
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
    assert_raises(Zee::App::AlreadyInitializedError) { Zee.app.initialize! }
  end

  test "prevents app from having the environment set after initialization" do
    slow_test
    app = Zee::App.new
    app.root = Pathname("tmp")
    app.initialize!

    assert_raises(Zee::App::AlreadyInitializedError) { app.env = :test }
  end

  test "runs init blocks" do
    slow_test
    app = Zee::App.new
    app.root = Pathname("tmp")
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
    stack = app.middleware.to_a.map(&:first)

    assert_equal Zee::Middleware::RequestLogger, stack[0]
    assert_equal RequestStore::Middleware, stack[1]
    assert_equal Rack::Sendfile, stack[2]
    assert_equal Zee::Middleware::Static, stack[3]
    assert_equal Rack::Runtime, stack[4]
    assert_equal Rack::Protection, stack[5]
    assert_equal Rack::Session::Cookie, stack[6]
    assert_equal Zee::Middleware::Flash, stack[7]
    assert_equal Rack::Head, stack[8]
    assert_equal Rack::ConditionalGet, stack[9]
    assert_equal Rack::ETag, stack[10]
    assert_equal Rack::TempfileReaper, stack[11]
    assert_equal Zee::Middleware::ContentSecurityPolicy, stack[12]
    assert_equal 13, stack.size
  end

  test "enables template caching" do
    template_name = "tmp/template.erb"

    create_file template_name, <<~ERB
      <%= name %>
    ERB

    template = Tilt.new(
      template_name,
      engine_class: Erubi::CaptureBlockEngine,
      freeze_template_literals: false,
      escape: true,
      bufval: Zee::BUFVAL,
      bufvar: Zee::BUFVAR
    )

    Tilt.expects(:new).once.with(template_name, anything).returns(template)

    Zee.app.config.set(:enable_template_caching, true)
    Zee.app.render_template(template_name, locals: {name: "John"})
    Zee.app.render_template(template_name, locals: {name: "John"})
  end

  test "instantes a new template when template caching is disabled" do
    template_name = "tmp/template.erb"

    create_file template_name, <<~ERB
      <%= name %>
    ERB

    template = Tilt.new(
      template_name,
      engine_class: Erubi::CaptureBlockEngine,
      freeze_template_literals: false,
      escape: true,
      bufval: Zee::BUFVAL,
      bufvar: Zee::BUFVAR
    )

    Tilt.expects(:new).twice.with(template_name, anything).returns(template)

    Zee.app.config.set(:enable_template_caching, false)
    Zee.app.render_template(template_name, locals: {name: "John"})
    Zee.app.render_template(template_name, locals: {name: "John"})
  end
end
