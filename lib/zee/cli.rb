# frozen_string_literal: true

require "thor"
require "shellwords"
require "securerandom"
require "pathname"
require_relative "../zee"
require_relative "generators/app"
require_relative "generators/migration"
require_relative "cli/secrets"
require_relative "cli/generate"

module Zee
  # @private
  class CLI < Thor
    check_unknown_options!

    # :nocov:
    def self.exit_on_failure?
      true
    end
    # :nocov:

    desc "new PATH", "Create a new app"
    option :skip_bundle, type: :boolean,
                         default: false,
                         desc: "Skip bundle install",
                         aliases: "-B"
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

    no_commands do
      # Add helper methods here
    end
  end
end
