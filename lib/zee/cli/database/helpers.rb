# frozen_string_literal: true

module Zee
  module CLI
    class Database < Command
      class Helpers < CLI::Helpers
        def migrations_dir
          Pathname("db/migrations")
        end

        def applied_migrations
          connection[:schema_migrations]
            .all
            .map { _1[:filename] }
            .sort
        end

        def dump_schema
          connection.extension(:schema_dumper)

          content = <<~CONTENT
            # frozen_string_literal: true

            # This file is auto-generated from the current state of the database.
            #
            # You can use `zee db:schema:load` to load the schema, which tends to
            # be faster and is potentially less error prone than running all of your
            # migrations from scratch. Old migrations may fail to apply correctly if
            # those migrations use external dependencies or application code.
            #
            # It's strongly recommended that you check this file into your version
            # control system.
            #{connection.dump_schema_migration.chomp if applied_migrations.any?}
          CONTENT

          content.gsub!(/^ +$/, "")

          File.write("db/schema.rb", content)
        end

        def connection
          @connection ||= Sequel.connect(connection_string, logger:)
        end

        def connect
          # Establish connection
          connection

          # Load setup if available
          setup_file = File.expand_path("database/setup.rb")
          require setup if File.file?(setup_file)
        end

        def logger
          return unless options[:verbose]

          @logger ||= ::Logger.new($stdout, level: ::Logger::INFO)
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
          CLI.load_dotenv_files(*dotenvs)

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
