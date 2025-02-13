# frozen_string_literal: true

require "thor"
require "shellwords"
require "securerandom"
require "pathname"
require "logger"
require_relative "ext/thor"
require_relative "../zee"
require_relative "generators/app"
require_relative "generators/migration"
require_relative "generators/model"
require_relative "command"
require_relative "cli/helpers"
require_relative "migration_modifier_parser"
require_relative "cli/secrets"
require_relative "cli/generate"
require_relative "cli/database"

module Zee
  # @private
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

    def self.before_run_hooks
      @before_run_hooks ||= Hash.new {|h, k| h[k] = [] }
    end

    include Database
    include Secrets

    desc "new PATH", "Create a new app"
    option :skip_bundle, type: :boolean,
                         default: false,
                         desc: "Skip bundle install",
                         aliases: "-B"
    option :database, type: :string,
                      default: "sqlite",
                      desc: "Set the database",
                      aliases: "-d",
                      enum: %w[sqlite postgresql mysql mariadb]
    def new(path)
      generator = Generators::App.new
      generator.destination_root = File.expand_path(path)
      generator.options = options
      generator.invoke_all
    end

    desc "console", "Start a console"
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

    desc "generate SUBCOMMAND", "Generate new code"
    subcommand "generate", Generate

    no_commands do
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
