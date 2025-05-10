# frozen_string_literal: true

module Zee
  module CLI
    class Root < Command
      desc "test [FILE|DIR...]", "Run tests"
      option :seed,
             type: :string,
             aliases: "-s",
             desc: "Set a specific seed"
      option :backtrace,
             type: :boolean,
             default: false,
             aliases: "-b",
             desc: "Show full backtrace"
      option :slow,
             type: :boolean,
             default: false,
             desc: "Run slow tests"
      option :wait,
             type: :numeric,
             desc: "Set a custom wait time for the integration server to start",
             default: 5.0
      # :nocov:
      def test(*files)
        cmd = [
          "bin/zee test %{location}:%{line} \e[34m# %{description}\e[0m",
          ("-s #{options[:seed]}" if options[:seed])
        ].compact.join(" ").strip

        $LOAD_PATH << File.join(Dir.pwd, "test")

        ENV["MT_TEST_COMMAND"] = cmd
        ENV["ZEE_ENV"] = "test"
        CLI.load_dotenv_files(".env.test", ".env")

        require "./test/test_helper" if File.file?("test/test_helper.rb")
        require "minitest/utils"

        pattern = []
        test_name = nil

        files = files.map do |file|
          if File.directory?(file)
            pattern << "#{file}/**/*_test.rb"
            next
          end

          location, line = file.split(":")

          if line
            text = File.read(location).lines[line.to_i - 1]
            description = text.strip[/^.*?test\s+["'](.*?)["']\s+do.*?$/, 1]
            test_name = Minitest::Test.test_method_name(description)
          end

          File.expand_path(location)
        end

        pattern = ["./test/**/*_test.rb"]
        pattern = files if files.any?
        files = Dir[*pattern]
        has_system_test = files.any? { _1.include?("/system/") }

        args = []
        args.push("--slow") if options[:slow]
        args.push("--name", test_name.to_s) if test_name
        args.push("--seed", options[:seed]) if options[:seed]
        args.push("--backtrace") if options[:backtrace]

        if files.empty?
          raise Thor::Error, set_color("ERROR: No test files found.", :red)
        end

        files.each { require _1 }

        setup_for_system_tests if has_system_test
        exit(Minitest.run(args) ? 0 : 1)
      end
      # :nocov:

      no_commands do
        # :nocov:
        def find_available_port
          server = TCPServer.new("127.0.0.1", 0)
          port = server.addr[1]
          server.close
          port
        end

        def setup_for_system_tests
          port = ENV.fetch("CAPYBARA_SERVER_PORT", find_available_port)
          ENV["CAPYBARA_SERVER_PORT"] = port.to_s
          ENV["ZEE_ENV"] = "test"
          ENV["ZEE_INTEGRATION_SERVER"] = "true"

          $stdout.sync = true
          $stderr.sync = true

          pid = Process.spawn(
            "bundle",
            "exec",
            "puma",
            "--environment", "test",
            "--config", "./config/puma.rb",
            "--silent",
            "--quiet",
            "--bind", "tcp://127.0.0.1:#{port}"
          )
          at_exit { Process.kill("INT", pid) }
          Process.detach(pid)

          shell.say(
            "Integration test server: http://127.0.0.1:#{port} [pid=#{pid}]"
          )

          require "net/http"
          waited_time = 0
          step = 0.05

          loop do
            waited_time += step
            uri = URI("http://127.0.0.1:#{port}/")

            begin
              Net::HTTP.get_response(uri)
              break
            rescue Errno::ECONNREFUSED
              if waited_time > options[:wait]
                raise Thor::Error,
                      set_color("ERROR: Unable to start Puma at #{uri}", :red)
              end

              sleep(step)
            end
          end
        end
        # :nocov:
      end
    end
  end
end
