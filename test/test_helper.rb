# frozen_string_literal: true

ENV["APP_ENV"] = "test"

require "simplecov"
SimpleCov.start do
  add_filter("test/")
end

require "bundler/setup"
Bundler.setup(:default, :development)

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

module Minitest
  class Test
    setup { ENV.delete("MINITEST_TEST_COMMAND") }
    setup { ENV.delete_if { _1.start_with?("ZEE") } }
    setup { FileUtils.rm_rf("tmp") }
    setup { FileUtils.mkdir("tmp") }
    setup { Zee.app = SampleAppInstance }
    setup { I18n.backend.reload! }
    setup { I18n.available_locales = [:en] }

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

      File.write("tmp/template.erb", template)
      Zee.app.render_template("tmp/template.erb", request:, locals:)
    end

    def store_translations(locale, translations)
      I18n.backend.store_translations(locale, translations)
    end
  end
end
