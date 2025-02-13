# frozen_string_literal: true

require "simplecov"
SimpleCov.start

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

    def capture_exit(&)
      yield
    rescue SystemExit => error
      error.status
    end
  end
end
