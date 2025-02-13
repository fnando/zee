# frozen_string_literal: true

module Zee
  module Generators
    class Migration < Thor::Group
      include Thor::Actions

      attr_accessor :options
      attr_reader :locals

      def self.source_root
        File.join(__dir__, "migration")
      end

      # Supported:
      # zee generate migration create_users [...fields]
      # zee generate migration drop_users
      # zee generate migration remove_users
      # zee generate migration drop_email_from_users
      # zee generate migration remove_email_from_users
      # zee generate migration add_email_to_users [column:type:modifiers]
      # zee generate migration add_index_to_email_on_users
      # zee generate migration add_index_to_email_and_status_on_users
      # zee generate migration remove_index_from_email_on_users
      # zee generate migration drop_index_from_email_on_users
      def templates
        fields = options.fetch(:fields, [])
                        .map { MigrationModifierParser.call(_1) }
        name = options[:name].to_s.downcase.tr("-", "_")
        parse_name(
          name,
          fields
        ) => {operation:, table_name:, column:, file:, fields:}

        @locals = {operation:, table_name:, column:, fields:}
        migration_file = find_migration_file(name)

        if operation
          template "db/migrations/#{file}.rb.erb", migration_file
        else
          template "db/migrations/migration.rb.erb", migration_file
        end
      end

      no_commands do
        def find_migration_file(name)
          migrations = Dir[File.join(destination_root, "db/migrations/*.rb")]
          timestamp = Time.now.to_i
          migration_file = "db/migrations/#{timestamp}_#{name}.rb"

          # :nocov:
          if migrations.last.to_s.match?(/\d+_#{name}\.rb$/)
            migration_file = migrations.last
          end
          # :nocov:

          migration_file
        end

        def render_options(options)
          # TODO: remove this replace when support for ruby3.3 is dropped.
          options.inspect.gsub(/:(\w+)=>/, "\\1: ")[1..-2]
        end

        def parse_name(name, fields)
          default = {
            file: nil,
            operation: nil,
            table_name: nil,
            column: nil,
            fields:
          }

          case name
          when /^(?:remove|drop)_index_from_(.*?)_on_(.*?)$/
            column = Regexp.last_match(1).split("_and_").map(&:to_sym)

            default.merge(
              file: :index,
              operation: :drop_index,
              column:,
              table_name: Regexp.last_match(2)
            )
          when /^(?:add)_index_to_(.*?)_on_(.*?)$/
            column = Regexp.last_match(1).split("_and_").map(&:to_sym)

            default.merge(
              file: :index,
              operation: :add_index,
              column:,
              table_name: Regexp.last_match(2)
            )
          when /^(?:drop|remove)_(.*?)_from_(.*?)$/
            column = Regexp.last_match(1).split("_and_")

            default.merge(
              file: :column,
              operation: :drop_column,
              column:,
              table_name: Regexp.last_match(2)
            )
          when /^(?:add)_(.*?)_to_(.*?)$/
            column = Regexp.last_match(1).split("_and_").map(&:to_sym)

            column.each do |col|
              next if default[:fields].any? { _1[:name].to_sym == col }

              default[:fields] << MigrationModifierParser.call("#{col}:string")
            end

            default.merge(
              file: :column,
              operation: :add_column,
              column:,
              table_name: Regexp.last_match(2)
            )
          when /^create_(.*?)$/
            default.merge(
              file: :table,
              operation: :create_table,
              table_name: Regexp.last_match(1)
            )
          when /^(?:drop|remove)_(.*?)$/
            default.merge(
              file: :drop_table,
              operation: :drop_table,
              table_name: Regexp.last_match(1).split("_and_")
            )
          else
            default
          end
        end
      end
    end
  end
end
