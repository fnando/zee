# frozen_string_literal: true

module Zee
  class CLI < Command
    class Generate < Command
      desc "mailer NAME [METHODS...]", "Generate new mailer"
      def mailer(name, *methods)
        options[:name] = name
        options[:methods] = methods

        generator = Generators::Mailer.new
        generator.destination_root = File.expand_path(Dir.pwd)
        generator.options = options
        generator.invoke_all
      end

      desc "migration NAME [FIELDS...]", "Generate new migration"
      def migration(name, *fields)
        options[:name] = name
        options[:fields] = fields

        generator = Generators::Migration.new
        generator.destination_root = File.expand_path(Dir.pwd)
        generator.options = options
        generator.invoke_all
      end

      desc "model NAME [FIELDS...]", "Generate new model"
      def model(name, *fields)
        name = name.tr("-", "_").gsub(/s$/, "")
        model_name = name.split("_").map(&:capitalize).join

        fields << "id:primary_key" unless fields.any? { _1.start_with?("id:") }

        begin
          mod = Module.new
          mod.const_set(model_name, nil)
        rescue NameError
          raise Thor::Error, set_color("ERROR: Invalid model name", :red)
        end

        migration_name = "create_#{name}s"

        migration = Generators::Migration.new
        migration.destination_root = File.expand_path(Dir.pwd)
        migration.options = {name: migration_name, fields:}
        migration.invoke_all

        model = Generators::Model.new
        model.destination_root = File.expand_path(Dir.pwd)
        model.options = {file_name: name, model_name:}
        model.invoke_all
      end

      no_commands do
        # helpers
      end
    end
  end
end
