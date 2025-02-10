# frozen_string_literal: true

module Zee
  class CLI < Command
    class Database < Command
      def self.before_run
        require "sequel"
        require "logger"
      end

      class_option :verbose,
                   type: :boolean,
                   default: false,
                   desc: "Show more information",
                   aliases: "-v"

      desc "migrate", "Migrate the database"
      option :env,
             type: :string,
             default: "development",
             desc: "Set the environment",
             aliases: "-e",
             enum: %w[development test production]
      option :connection_string,
             type: :string,
             desc: "Set the connection string",
             aliases: "-c"
      def migrate
        Sequel.extension :migration, :core_extensions
        Sequel::Migrator.apply(connection, File.join(Dir.pwd, "db/migrations"))
      rescue Sequel::Migrator::Error => error
        # :nocov:
        raise Thor::Error, set_color("ERROR: #{error.message}", :red)
        # :nocov:
      end

      no_commands do
        def connection
          @connection ||= Sequel.connect(connection_string, logger:)
        end

        def logger
          return unless options[:verbose]

          @logger ||= Logger.new($stdout, level: Logger::INFO)
        end

        def connection_string
          @connection_string ||= options["connection_string"] ||
                                 compute_connection_string
        end

        def env
          options["env"]
        end

        def compute_connection_string
          require "dotenv"
          Dotenv.load(".env.#{env}", ".env")

          return ENV["DATABASE_URL"] if ENV["DATABASE_URL"]

          say_error "ERROR: No connection string found", :red
          say_error "\nTo connect to the database you must:"
          say_error "- provide a connection string using --connection-string"
          say_error "- have a .env or .env.#{env} file with DATABASE_URL"
          say_error "- set an environment variable DATABASE_URL"
          exit 1
        end
      end
    end
  end
end
