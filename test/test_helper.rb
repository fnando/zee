# frozen_string_literal: true

require "simplecov"
SimpleCov.start do
  add_filter("test/")
end

require "bundler/setup"
require "zee"
require "zee/cli"
require "rack/test"
require "rack/session"
require "rack/protection"

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
  end
end
