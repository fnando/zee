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
        args.push("--name", test_name.to_s) if test_name
        args.push("--seed", options[:seed]) if options[:seed]
        args.push("--backtrace") if options[:backtrace]

        if files.empty?
          raise Thor::Error, set_color("ERROR: No test files found.", :red)
        end

        files.each { require _1 }

        setup_for_system_tests if has_system_test
        Minitest.run(args)
      end
      # :nocov:

      no_commands do
        # :nocov:
        def setup_for_system_tests
          pid = Process.spawn(
            "bundle",
            "exec",
            "puma",
            "--environment", "test",
            "--config", "./config/puma.rb",
            "--silent",
            "--quiet",
            "--bind", "tcp://127.0.0.1:11100"
          )
          at_exit { Process.kill("INT", pid) }
          Process.detach(pid)

          shell.say(
            "Integration test server: http://localhost:11100 [pid=#{pid}]"
          )

          require "net/http"
          attempts = 0

          loop do
            attempts += 1
            uri = URI("http://localhost:11100/")

            begin
              Net::HTTP.get_response(uri)
              break
            rescue Errno::ECONNREFUSED
              if attempts == 10
                raise Thor::Error,
                      set_color("ERROR: Unable to start Puma at #{uri}", :red)
              end

              sleep 0.05
            end
          end
        end
        # :nocov:
      end
    end
  end
end
