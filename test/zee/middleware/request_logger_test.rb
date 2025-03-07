# frozen_string_literal: true

require "test_helper"

class RequestLoggerTest < Minitest::Test
  include Zee::Instrumentation

  let(:app) do
    Rack::Builder.app do
      use Zee::Middleware::RequestLogger
      use RequestStore::Middleware
      run(proc { [200, {}, []] })
    end
  end

  setup do
    Zee.app.config.set(:enable_instrumentation, true)
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
    instrument(:request, redirected_to: "/")
    instrument(:sequel, sql: "select 1", &block)

    Dir.chdir(root) { app.call(Rack::MockRequest.env_for("/")) }
    log = strip_ansi_color(logger_io.tap(&:rewind).read)

    assert_match(%r{^GET / \(.*?\)$}, log)
    assert_includes log, "Handler: pages#home\n"
    assert_includes log, "Redirected to: /\n"
    assert_match(%r{^View: app/views/pages/home\.html\.erb \(.*?\)$}, log)
    assert_match(%r{^Partial: app/views/pages/_item\.html\.erb \(.*?\)$}, log)
    assert_match(%r{^Layout: app/views/layouts/app\.html\.erb \(.*?\)$}, log)
    assert_match(/^Database: 1 query \(.*?\)$/, log)
    assert_includes log, "Status: 200 OK\n"
  end
end
