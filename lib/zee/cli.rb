# frozen_string_literal: true

require "thor"
require "shellwords"
require "securerandom"
require "pathname"
require "logger"
require_relative "ext/thor"
require_relative "../zee"

module Zee
  # @api private
  class CLI < Command
    PROMPT_ALIASES = {
      development: "dev",
      production: "prod",
      test: "test"
    }.freeze

    PROMPT_COLORS = {
      development: :blue,
      production: :red,
      test: :blue
    }.freeze

    class_option :help,
                 type: :boolean,
                 aliases: "-h",
                 desc: "Display help information"

    # Override the default start method so we can show help for subcommands.
    def self.start(given_args = ARGV, config = {})
      help = given_args.include?("--help") || given_args.include?("-h")

      if help && given_args[0] != "help"
        command = given_args[0]
        super(["help", command], config)
      else
        super
      end
    end

    def self.before_run_hooks
      @before_run_hooks ||= Hash.new {|h, k| h[k] = [] }
    end

    def self.load_dotenv_files(*files)
      require "dotenv"
      Dotenv.load(*files)
    rescue LoadError
      # :nocov:
      if files.any? {|file| File.exist?(file) }
        raise Thor::Error,
              set_color(
                "ERROR: to use a dotenv file, add `gem \"dotenv\"` " \
                "to your Gemfile",
                :red
              )
      end

      Dotenv.load(*files) if defined?(Dotenv)
      # :nocov:
    end

    include Database
    include Secrets

    def self.handle_no_command_error(command, *)
      bin = "./bin/#{command}" unless command == "zee"

      return system(bin, *ARGV) if bin && File.exist?(bin)

      shell = Thor::Base.shell.new
      shell.say_error "ERROR: Could not find command `#{command}`.\n\n", :red
      help(shell)

      exit 1
    end

    desc "routes", "List all routes"
    def routes
      require "bundler/setup"
      require "dotenv"
      require "terminal-table"

      Dotenv.load(".env", ".env.development", ".env.test", ".env.production")
      Bundler.require(:default)
      require "./config/environment" if File.file?("./config/environment.rb")

      normalize_to = proc do |to|
        next to if to.is_a?(String)
        next to.name if to.respond_to?(:name)
        next to.to_s unless to.is_a?(Proc)

        path, line = to.source_location
        path = Pathname(path).relative_path_from(Dir.pwd)
        "#{path}:#{line}"
      end

      routes = Zee.app.routes.to_a
      headings = %w[Verb Path Prefix To]
      rows = routes.map do |route|
        [
          route.via.map { _1.to_s.upcase }.join(", "),
          route.path,
          route.name,
          normalize_to.call(route.to)
        ]
      end

      table = ::Terminal::Table.new(rows:, headings:) do |t|
        t.style = {border_left: false, border_right: false, padding_right: 5}
      end

      puts table
    end

    desc "new PATH", "Create a new app"
    option :skip_bundle, type: :boolean,
                         default: false,
                         desc: "Skip bundle install",
                         aliases: "-B"
    option :skip_npm, type: :boolean,
                      default: false,
                      desc: "Skip npm install",
                      aliases: "-N"
    option :database, type: :string,
                      default: "sqlite",
                      desc: "Set the database",
                      aliases: "-d",
                      enum: %w[sqlite postgresql mysql mariadb]
    option :css,
           type: :string,
           default: "tailwind",
           enum: %w[tailwind],
           desc: "Use a CSS framework"
    option :js,
           type: :string,
           default: "typescript",
           enum: %w[js typescript],
           desc: "Use a JavaScript language"
    option :test,
           type: :string,
           default: "minitest",
           enum: %w[minitest],
           desc: "Use a test framework"
    def new(path)
      generator = Generators::App.new
      generator.destination_root = File.expand_path(path)
      generator.options = options
      generator.invoke_all

      say "\n==========", :red
      say "Important!", :red
      say "==========", :red
      say "We generated encryption keys at config/secrets/*.key"
      say "Save this in a password manager your team can access."
      say "Without the key, no one, including you, " \
          "can access the encrypted credentiails."

      say "\nTo start the app, run:"
      say "  bin/zee dev"
    end

    desc "console", "Start a console (alias: c)"
    option :env,
           type: :string,
           default: "development",
           desc: "Set the environment",
           aliases: "-e",
           enum: %w[development test production]
    # :nocov:
    def console
      require "bundler/setup"
      require "dotenv"
      require "irb"
      require "irb/completion"

      env =
        (ENV_NAMES.filter_map {|name| ENV[name] }.first || options[:env]).to_sym

      Dotenv.load(".env", ".env.#{env}")
      Bundler.require(:default, env)
      require "./config/environment"

      prompt_prefix = "%N(#{set_color(PROMPT_ALIASES.fetch(env),
                                      PROMPT_COLORS.fetch(env))})"

      IRB.setup(nil)
      IRB.conf[:PROMPT][:ZEE] = {
        PROMPT_I: "#{prompt_prefix}> ",
        PROMPT_S: "#{prompt_prefix}%l ",
        PROMPT_C: "#{prompt_prefix}* ",
        RETURN: "=> %s\n"
      }
      IRB.conf[:PROMPT_MODE] = :ZEE
      IRB::Irb.new.run(IRB.conf)
    end
    # :nocov:

    desc "generate SUBCOMMAND", "Generate new code (alias: g)"
    subcommand "generate", Generate

    desc "test [FILE|DIR...]", "Run tests"
    option :seed,
           type: :string,
           aliases: "-s",
           desc: "Set a specific seed"
    # :nocov:
    def test(*files)
      cmd = [
        "bin/zee test %{location}:%{line} \e[34m# %{description}\e[0m",
        ("-s #{options[:seed]}" if options[:seed])
      ].compact.join(" ").strip

      $LOAD_PATH << File.join(Dir.pwd, "test")

      ENV["MINITEST_TEST_COMMAND"] = cmd
      ENV["ZEE_ENV"] = "test"
      CLI.load_dotenv_files(".env.test", ".env")
      ARGV.clear

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
      has_integration_test = files.any? { _1.include?("/integration/") }

      ARGV.push("--name", test_name.to_s) if test_name
      ARGV.push("--seed", options[:seed]) if options[:seed]

      if files.empty?
        raise Thor::Error, set_color("ERROR: No test files found.", :red)
      end

      files.each { require _1 }

      setup_for_integration_tests if has_integration_test
      Minitest.run
    end
    # :nocov:

    desc "dev", "Start the dev server (requires ./bin/dev)"
    # :nocov:
    def dev
      pid = Process.spawn("./bin/dev")
      signals = %w[INT]

      signals.each do |signal|
        Signal.trap(signal) do
          Process.kill(signal, pid)
        rescue Errno::ESRCH
          # Process already gone
        end
      rescue ArgumentError
        # Skip signals that can't be trapped
      end

      Process.wait(pid)
    end
    # :nocov:

    desc "assets", "Build assets"
    option :digest,
           type: :boolean,
           default: true,
           desc: "Enable asset digesting"
    option :prefix,
           type: :string,
           default: "/assets",
           desc: "The request path prefix"
    def assets
      bins = %w[bin/styles bin/scripts]

      FileUtils.rm_rf("public/assets")
      FileUtils.mkdir_p("public/assets")

      bins.each do |bin|
        bin = Pathname(bin)

        unless bin.file?
          raise Thor::Error,
                set_color("ERROR: #{bin} not found", :red)
        end

        unless bin.executable?
          raise Thor::Error,
                set_color("ERROR: #{bin} is not executable", :red)
        end

        # Export styles and scripts
        system(bin.to_s)
      end

      # Copy other assets
      Dir["./app/assets/{fonts,images}"].each do |dir|
        FileUtils.cp_r(dir, "public/assets/")
      end

      AssetsManifest.new(
        source: Pathname(Dir.pwd).join("public/assets"),
        digest: options[:digest],
        prefix: options[:prefix]
      ).call
    end

    no_commands do
      # :nocov:
      def setup_for_integration_tests
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
        Process.detach(pid)

        shell.say "Integration test server: http://localhost:11100 [pid=#{pid}]"

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

        at_exit { Process.kill("INT", pid) }
      end
      # :nocov:

      def db_helpers
        @db_helpers ||= Database::Helpers.new(options:, shell:)
      end

      # :nocov:
      def secrets_helpers
        @secrets_helpers ||= Secrets::Helpers.new(options:, shell:)
      end
      # :nocov:
    end
  end
end
