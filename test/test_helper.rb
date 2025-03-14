# frozen_string_literal: true

ENV["APP_ENV"] = "test"

$stdout.sync = true
require "English"
require "simplecov"

SimpleCov.start do
  add_filter("test/")
  add_filter("cache_store/null")
end

require "bundler/setup"
Bundler.setup(:default, :development)

require_relative "support/warning"
require "zee"
require "zee/cli"
require "rack/test"
require "rack/session"
require "rack/protection"
require "nokogiri"
require "sequel"
require "minitest/utils"
require "minitest/autorun"

Dir["#{__dir__}/support/**/*.rb"].each do |file|
  require file
end

Dir.chdir(File.join(__dir__, "fixtures/sample_app")) do
  require_relative "fixtures/sample_app/app"
end

Minitest::Utils::Reporter.filters << %r{/gems/}

module Minitest
  class Test
    let(:logger_io) { StringIO.new }
    let(:logger) { Zee::Logger.new(Logger.new(logger_io)) }

    setup do
      Zeitwerk::Registry.loaders[1..-1]
                        .each { Zeitwerk::Registry.unregister_loader(_1) }
    end

    setup { ENV.delete("MINITEST_TEST_COMMAND") }
    setup { ENV.delete_if { _1.start_with?("ZEE") } }
    setup { ENV["APP_ENV"] = "test" }
    setup { FileUtils.rm_rf("tmp") }
    setup { FileUtils.mkdir("tmp") }
    setup { Zee.app = SampleApp.create }
    setup { I18n.backend.reload! }
    setup { I18n.available_locales = [:en] }
    setup { RequestStore.store.clear }
    setup { Zee.app.config.set(:logger, logger) }
    setup { Zee.error = Zee::ErrorReporter.new }

    teardown { FileUtils.rm_rf("tmp") }

    def capture(shell: false, &)
      exit_code = 0

      out, err, = capture_subprocess_io do
        yield
      rescue SystemExit => error
        exit_code = error.status
      end

      exit_code = $CHILD_STATUS.exitstatus if shell

      {out:, err:, exit_code:}
    end

    def render(
      template,
      controller: nil,
      request: nil,
      context: nil,
      locals: {}
    )
      request ||= Zee::Request.new(
        Rack::MockRequest
          .env_for("/")
          .merge("rack.session" => {Zee::CSRF_SESSION_KEY => "abc"})
      )
      controller ||= Zee::Controller.new(
        action_name: "show",
        controller_name: "example",
        request:,
        response: Zee::Response.new
      )
      context ||= Object.new.extend(Zee.app.helpers)
      File.write("tmp/template.erb", template)
      FileUtils.mkdir_p("tmp/config")
      FileUtils.cp_r("test/fixtures/sample_app/config/secrets", "tmp/config/")
      Dir.chdir("tmp") do
        Zee.app.render_template(
          "template.erb",
          request:,
          locals:,
          context:,
          controller:
        )
      end
    end

    def store_translations(locale, translations)
      I18n.backend.store_translations(locale, translations)
    end

    def strip_ansi_color(string)
      string.gsub(/\e\[(\d+)(;\d+)*m/, "")
    end

    def create_file(path, content)
      FileUtils.mkdir_p(File.dirname(path))
      File.write(path, content)
    end
  end
end
