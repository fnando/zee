# frozen_string_literal: true

require "thor"
require "shellwords"
require "securerandom"
require "pathname"
require "forwardable"
require "logger"
require_relative "ext/thor"
require_relative "../zee"
require_relative "generators/app"
require_relative "generators/migration"
require_relative "command"
require_relative "cli/helpers"
require_relative "cli/secrets"
require_relative "cli/generate"
require_relative "cli/database"

module Zee
  # @private
  class CLI < Command
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
