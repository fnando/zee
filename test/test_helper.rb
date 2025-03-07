# frozen_string_literal: true

ENV["APP_ENV"] = "test"

require "simplecov"
SimpleCov.start do
  add_filter("test/")
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
    setup { FileUtils.rm_rf("tmp") }
    setup { FileUtils.mkdir("tmp") }
    setup { Zee.app = SampleApp.create }
    setup { I18n.backend.reload! }
    setup { I18n.available_locales = [:en] }
    setup { RequestStore.store.clear }
    setup { Zee.app.config.set(:logger, logger) }

    teardown { FileUtils.rm_rf("tmp") }

    def capture(&)
      exit_code = 0

      out, err, = capture_subprocess_io do
        yield
      rescue SystemExit => error
        exit_code = error.status
      end

      {out:, err:, exit_code:}
    end

    def render(template, request: nil, locals: {})
      request ||= Zee::Request.new(Rack::MockRequest.env_for("/"))
      context = Struct.new(:request).new(request)
                      .extend(Zee::ViewHelpers::Form)
                      .extend(Zee::ViewHelpers::HTML)
      File.write("tmp/template.erb", template)
      Zee.app.render_template("tmp/template.erb", request:, locals:, context:)
    end

    def store_translations(locale, translations)
      I18n.backend.store_translations(locale, translations)
    end

    def strip_ansi_color(string)
      string.gsub(/\e\[(\d+)(;\d+)*m/, "")
    end
  end
end
