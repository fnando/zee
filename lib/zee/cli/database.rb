# frozen_string_literal: true

module Zee
  class CLI < Command
    module Database
      class Helpers < CLI::Helpers
        def connection
          @connection ||= Sequel.connect(connection_string, logger:)
        end

        def logger
          return unless options[:verbose]

          @logger ||= Logger.new($stdout, level: Logger::INFO)
        end

        def connection_string
          @connection_string ||= options[:connection_string] ||
                                 compute_connection_string
        end

        def env
          options[:env]
        end

        def compute_connection_string
          dotenvs = [".env.#{env}", ".env"]

          return ENV["DATABASE_URL"] if ENV["DATABASE_URL"]

          begin
            require "dotenv"
          rescue LoadError
            # :nocov:
            if dotenvs.any? {|file| File.exist?(file) }
              raise Thor::Error,
                    set_color(
                      "ERROR: to use a dotenv file, add `gem \"dotenv\"` " \
                      "to your Gemfile",
                      :red
                    )
            end
            # :nocov:
          end

          Dotenv.load(*dotenvs) if defined?(Dotenv)

          return ENV["DATABASE_URL"] if ENV["DATABASE_URL"]

          say_error "ERROR: No connection string found", :red
          say_error "\nTo connect to the database you must:"
          say_error "- provide a connection string using --connection-string"
          say_error "- have a .env or .env.#{env} file with DATABASE_URL"
          say_error "- set an environment variable DATABASE_URL"
          exit 1
        end
      end

      def self.included(base)
        base.before_run_hooks[:db] << lambda do
          require "sequel"
        end

        base.class_eval do
          class_option :verbose,
                       type: :boolean,
                       default: false,
                       desc: "Show more information",
                       aliases: "-v"

          desc "db:migrate", "Migrate the database"
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
          define_method :"db:migrate" do
            Sequel.extension :migration, :core_extensions
            Sequel::Migrator.apply(
              db_helpers.connection,
              File.join(Dir.pwd, "db/migrations")
            )
          rescue Sequel::Migrator::Error => error
            # :nocov:
            raise Thor::Error, set_color("ERROR: #{error.message}", :red)
            # :nocov:
          end
        end
      end
    end
  end
end
