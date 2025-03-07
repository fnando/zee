# frozen_string_literal: true

require "test_helper"

class RequestLoggerTest < Minitest::Test
  include Zee::Instrumentation

  let(:io) { StringIO.new }
  let(:app) do
    Rack::Builder.app do
      use Zee::Middleware::RequestLogger
      use RequestStore::Middleware
      run(proc { [200, {}, []] })
    end
  end

  setup do
    Zee.app.config.set(:logger, Zee::Logger.new(Logger.new(io)))
    Zee.app.env.stubs(:development?).returns(true)
  end

  test "logs request" do
    root = Zee.app.root
    views = root.join("app/views")
    block = proc do
      # noop
    end

    instrument(:request, view: views.join("pages/home.html.erb"), &block)
    instrument(:request, partial: views.join("pages/_item.html.erb"), &block)
    instrument(:request, partial: views.join("pages/_item.html.erb"), &block)
    instrument(:request, partial: views.join("pages/_item.html.erb"), &block)
    instrument(:request, layout: views.join("layouts/app.html.erb"), &block)
    instrument(:request, route: "pages#home")
    instrument(:sequel, sql: "select 1", &block)

    Dir.chdir(root) { app.call(Rack::MockRequest.env_for("/")) }
    log = strip_ansi_color(io.tap(&:rewind).read)

    assert_match(%r{^GET / \(.*?\)$}, log)
    assert_includes log, "handler: pages#home\n"
    assert_match(%r{^view: app/views/pages/home\.html\.erb \(.*?\)$}, log)
    assert_match(%r{^partial: app/views/pages/_item\.html\.erb \(.*?\)$}, log)
    assert_match(%r{^layout: app/views/layouts/app\.html\.erb \(.*?\)$}, log)
    assert_match(/^database: 1 query \(.*?\)$/, log)
    assert_includes log, "status: 200 OK\n"
  end
end
