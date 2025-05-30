# frozen_string_literal: true

ENV["APP_ENV"] = "test"

$stdout.sync = true
require "English"
require "simplecov"
require "simplecov-tailwindcss"

SimpleCov.formatter = SimpleCov::Formatter::TailwindFormatter

SimpleCov.start do
  add_filter("test/")
  add_group("Controller", "controller")
  add_group("Core Extensions", "core")
  add_group("Generators", "generators")
  add_group("Middleware", "middleware")
  add_group("Plugins", "plugins")
  add_group("Sequel", "sequel")
  add_group("View Helpers", "view_helpers")
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
require "connection_pool"
require "redis"

SimpleCov.external_at_exit = true

Dir["#{__dir__}/support/**/*.rb"].each do |file|
  require file
end

Dir.chdir(File.join(__dir__, "fixtures/sample_app")) do
  require_relative "fixtures/sample_app/app"
end

Minitest::Utils::Reporter.filters << %r{/gems/}

SAMPLE_APP = SampleApp.create
TRANSLATION_FILES = Dir[
  "#{__dir__}/../lib/zee/translations/*.yml",
  "#{__dir__}/../lib/sequel/**/*.yml"
]

module Minitest
  class Test
    let(:logger_io) { StringIO.new }
    let(:logger) { Zee::Logger.new(Logger.new(logger_io)) }

    setup { ENV.delete("MINITEST_TEST_COMMAND") }
    setup { ENV.delete_if { _1.start_with?("ZEE") } }
    setup { ENV["APP_ENV"] = "test" }
    setup { FileUtils.rm_rf("tmp") }
    setup { FileUtils.mkdir("tmp") }

    setup do
      # These setup step resets the sample app to a known state for each test.
      Zee.app = SAMPLE_APP
      Zee.app.root = Pathname.new(__dir__).join("fixtures/sample_app")
      Zee.app.view_paths.clear
      Zee.app.view_paths << Zee.app.root.join("app/views")
      I18n.available_locales = %w[en pt-BR]
      I18n.locale = "en"
      I18n.load_path = TRANSLATION_FILES
      I18n.backend.reload!
    end

    setup { RequestStore.store.clear }
    setup { Zee.app.config.set(:logger, logger) }
    setup { Zee.error = Zee::ErrorReporter.new }
    setup { Zee::Template.cache.clear }

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

      path = Pathname.pwd.join("tmp/app/app/helpers/app.rb")
      FileUtils.mkdir_p(path.dirname)
      path.write <<~RUBY
        module Helpers
          module App
          end
        end
      RUBY

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
