# frozen_string_literal: true

module Zee
  class CLI < Command
    module Database
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

      def self.included(base)
        base.before_run_hooks[:db] << lambda do
          require "sequel"
        end

        base.class_eval do
          define_common_options = lambda do
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
          end

          class_option :verbose,
                       type: :boolean,
                       default: false,
                       desc: "Show more information",
                       aliases: "-v"

          desc "db:migrate", "Migrate the database"
          define_common_options.call
          define_method :"db:migrate" do
            Sequel.extension :migration, :core_extensions
            Sequel::TimestampMigrator.apply(
              db_helpers.connection,
              File.join(Dir.pwd, "db/migrations")
            )
            db_helpers.dump_schema
          rescue Sequel::Migrator::Error => error
            # :nocov:
            raise Thor::Error, set_color("ERROR: #{error.message}", :red)
            # :nocov:
          end

          desc "db:schema:dump", "Dump the current database schema"
          define_common_options.call
          define_method :"db:schema:dump" do
            db_helpers.dump_schema
          end

          desc "db:schema:load", "Load the database schema"
          define_common_options.call
          define_method :"db:schema:load" do
            Sequel.extension :migration, :core_extensions

            contents = File.read(File.join(Dir.pwd, "db/schema.rb"))
            contents.gsub!(
              "Sequel.migration",
              "DatabaseSchema = Sequel.migration"
            )
            eval(contents) # rubocop:disable Security/Eval
            DatabaseSchema.apply(db_helpers.connection, :up)
            rows = Dir[File.join(Dir.pwd, "db/migrations/*.rb")]
                   .map { {filename: File.basename(_1)} }

            db_helpers.connection[:schema_migrations].multi_insert(rows)
          end

          desc "db:undo", "Rollback to the previous schema (alias: db:rollback)"
          define_common_options.call
          define_method :"db:undo" do
            Sequel.extension :migration, :core_extensions
            filenames = db_helpers
                        .connection[:schema_migrations]
                        .map {|opts| opts[:filename] }
                        .sort

            return if filenames.empty?

            Sequel::TimestampMigrator.run_single(
              db_helpers.connection,
              db_helpers.migrations_dir.join(filenames.last),
              direction: :down
            )
            db_helpers.dump_schema
          end

          desc "db:redo", "Re-apply the current migration"
          define_common_options.call
          define_method :"db:redo" do
            public_send :"db:undo"
            public_send :"db:migrate"
          end
        end
      end
    end
  end
end
