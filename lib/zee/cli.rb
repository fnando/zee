# frozen_string_literal: true

require "thor"
require "shellwords"
require "securerandom"
require "pathname"
require_relative "ext/thor"
require_relative "../zee"
require_relative "generators/app"
require_relative "generators/migration"
require_relative "command"
require_relative "cli/secrets"
require_relative "cli/generate"
require_relative "cli/database"

module Zee
  # @private
  class CLI < Command
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

    desc "secrets SUBCOMMAND", "Secrets management"
    subcommand "secrets", Secrets

    desc "generate SUBCOMMAND", "Generate new code"
    subcommand "generate", Generate

    desc "db SUBCOMMAND", "Database management"
    subcommand "db", Database

    no_commands do
      # Add helper methods here
    end
  end
end
