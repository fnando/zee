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

    instrument(:request, scope: :view, path: views.join("pages/home.html.erb"),
               &block)
    instrument(:request, scope: :partial,
                         path: views.join("pages/_item.html.erb"), &block)
    instrument(:request, scope: :partial,
                         path: views.join("pages/_item.html.erb"), &block)
    instrument(:request, scope: :partial,
                         path: views.join("pages/_item.html.erb"), &block)
    instrument(:request, scope: :layout,
                         path: views.join("layouts/app.html.erb"), &block)
    instrument(:request, scope: :route, name: "pages#home")
    instrument(:request, scope: :before_action,
                         redirected_to: "/",
                         source: :some_before_action.inspect)
    instrument(:sequel, sql: "select 1", &block)
    instrument(:mailer, mailer: "mymailer#hello",
                        scope: :view,
                        path: views.join("mailer/hello.html.erb"), &block)
    instrument(:mailer, mailer: "mymailer#hello",
                        scope: :layout,
                        path: views.join("layouts/mailer.html.erb"), &block)
    instrument(:mailer, mailer: "mymailer#hello", scope: :delivery, &block)

    Dir.chdir(root) do
      app.call(
        Rack::MockRequest.env_for(
          "/?email=me@example.com",
          params: {email: "me@example.com"},
          method: :post
        )
      )
    end
    log = strip_ansi_color(logger_io.tap(&:rewind).read)

    assert_match(%r{^POST /\?email=filtered \(.*?\)$}, log)
    assert_includes log, "Handler: pages#home\n"
    assert_includes log, "Halted by: :some_before_action\n"
    assert_match(/Params: {"email" ?=> ?"\[filtered\]"}\n/, log)
    assert_match(%r{^View: app/views/pages/home\.html\.erb \(.*?\)$}, log)
    assert_match(%r{^Partial: app/views/pages/_item\.html\.erb \(.*?\)$}, log)
    assert_match(%r{^Layout: app/views/layouts/app\.html\.erb \(.*?\)$}, log)
    assert_match(/^Database: 1 query \(.*?\)$/, log)
    assert_match(
      %r{^Mail view: app/views/mailer/hello\.html\.erb \(.*?\)$}, log
    )
    assert_match(
      %r{^Mail layout: app/views/layouts/mailer\.html\.erb \(.*?\)$}, log
    )
    assert_match(/^Mail delivery: mymailer#hello \(.*?\)$/, log)
    assert_includes log, "Status: 200 OK\n"
  end
end
