# frozen_string_literal: true

module Zee
  module CLI
    class Database < Command
      default_command :open

      class_option :env,
                   type: :string,
                   default: "development",
                   desc: "Set the environment",
                   aliases: "-e",
                   enum: %w[development test production]
      class_option :connection_string,
                   type: :string,
                   desc: "Set the connection string",
                   aliases: "-c"

      class_option :verbose,
                   type: :boolean,
                   default: false,
                   desc: "Show more information",
                   aliases: "-v"

      desc "open", "Open the database console"
      long_desc <<~TEXT
        Open the database console using the connection string provided in
        the DATABASE_URL environment variable, dotenv files, or specified
        via the `--connection-string` switch.

        For SQLite databases, it will also load extensions from your local
        `.sqlpkg` directory automatically. Currently, it is not possible to
        load extensions from other locations. For more information on
        installing SQLite extensions, see <https://sqlpkg.org>.
      TEXT
      # :nocov:
      def open
        uri = URI(helpers.connection_string)

        args =
          case uri.scheme
          when "sqlite"
            extensions =
              Dir[".sqlpkg/**/*.{dylib,so}"].flat_map do |file|
                dir = File.dirname(file)
                basename = File.basename(file, ".*")

                ["-cmd", ".load #{File.join(dir, basename)}"]
              end

            unless uri.opaque == ":memory:"
              path = File.join(uri.hostname, uri.path)
            end

            ["sqlite3", *extensions, path].compact
          when "postgres"
            ["psql", helpers.connection_string]
          when "mysql", "mysql2"
            mysql_args = []
            mysql_args.push("--user", uri.user) if uri.user
            mysql_args.push("--host", uri.hostname) if uri.hostname
            mysql_args.push("--port", uri.port) if uri.port
            unless uri.path.empty?
              mysql_args.push("--database=name", uri.path[1..-1])
            end
            mysql_args.push("-p#{uri.password}") if uri.password

            ["mysql", *mysql_args]
          else
            raise Thor::Error,
                  set_color("Unsupported database type: #{uri.scheme}://",
                            :red)
          end

        system(*args)
      end
      # :nocov:

      desc "migrate", "Migrate the database"
      def migrate
        Sequel.extension :migration, :core_extensions
        helpers.connect

        Sequel::TimestampMigrator.apply(
          helpers.connection,
          File.join(Dir.pwd, "db/migrations")
        )
        helpers.dump_schema
      rescue Sequel::Migrator::Error => error
        # :nocov:
        raise Thor::Error, set_color("ERROR: #{error.message}", :red)
        # :nocov:
      end

      desc "schema ACTION", "Dump or load the database schema"
      def schema(action)
        unless %w[dump load].include?(action)
          help

          raise Thor::Error,
                set_color("Error: Invalid option: #{action.inspect}", :red)
        end

        return helpers.dump_schema if action == "dump"

        load_schema
      end

      map "rollback" => :undo
      desc "undo", "Rollback to the previous schema"
      def undo
        Sequel.extension :migration, :core_extensions
        helpers.connect

        filenames = helpers
                    .connection[:schema_migrations]
                    .map {|opts| opts[:filename] }
                    .sort

        return if filenames.empty?

        Sequel::TimestampMigrator.run_single(
          helpers.connection,
          helpers.migrations_dir.join(filenames.last),
          direction: :down
        )
        helpers.dump_schema
      end

      desc "redo", "Re-apply the current migration"
      def redo
        undo
        migrate
      end

      no_commands do
        def invoke_command(*)
          require "sequel"
          super
        end

        def helpers
          @helpers ||= Helpers.new(options:, shell:)
        end

        def load_schema
          Sequel.extension :migration, :core_extensions
          helpers.connect

          contents = File.read(File.join(Dir.pwd, "db/schema.rb"))
          contents.gsub!(
            "Sequel.migration",
            "DatabaseSchema = Sequel.migration"
          )
          eval(contents) # rubocop:disable Security/Eval
          DatabaseSchema.apply(helpers.connection, :up)
          rows = Dir[File.join(Dir.pwd, "db/migrations/*.rb")]
                 .map { {filename: File.basename(_1)} }

          helpers.connection[:schema_migrations].multi_insert(rows)
        end
      end
    end
  end
end
