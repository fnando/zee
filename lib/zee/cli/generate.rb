# frozen_string_literal: true

module Zee
  module CLI
    class Generate < Command
      if available?("minitest")
        desc "system_test NAME", "Generate a new system test"
        def system_test(name)
          load_environment(env_vars: false)

          generator = Generators::SystemTest.new
          generator.destination_root = File.expand_path(Dir.pwd)
          generator.options = {name:}
          generator.invoke_all
        end
      end

      desc "mailer NAME [METHODS...]", "Generate new mailer"
      def mailer(name, *methods)
        options[:name] = name
        options[:methods] = methods

        load_environment(env_vars: false)

        generator = Generators::Mailer.new
        generator.destination_root = File.expand_path(Dir.pwd)
        generator.options = options
        generator.invoke_all
      end

      desc "controller NAME [ACTIONS...]", "Generate new controller"
      def controller(name, *actions)
        options[:name] = name
        options[:actions] = actions

        load_environment(env_vars: false)

        generator = Generators::Controller.new
        generator.destination_root = File.expand_path(Dir.pwd)
        generator.options = options
        generator.invoke_all
      end

      desc "migration NAME [FIELDS...]", "Generate new migration"
      def migration(name, *fields)
        options[:name] = name
        options[:fields] = fields

        load_environment(env_vars: false)

        generator = Generators::Migration.new
        generator.destination_root = File.expand_path(Dir.pwd)
        generator.options = options
        generator.invoke_all
      end

      desc "model NAME [FIELDS...]", "Generate new model"
      def model(name, *fields)
        load_environment(env_vars: false)

        name = name.tr("-", "_").gsub(/s$/, "")
        model_name = name.split("_").map(&:capitalize).join

        unless fields.any? { _1.start_with?("id:") }
          fields.unshift("id:primary_key")
        end

        add_timestamps =
          fields.any? { _1 == "timestamps" } ||
          fields.none? { _1.start_with?("timestamps:false") }

        if add_timestamps
          fields += %w[
            created_at:datetime:null(false)
            updated_at:datetime:null(false)
          ]
        end

        fields = fields
                 .reject { _1.start_with?("timestamps") }
                 .map { _1.include?(":null") ? _1 : "#{_1}:null(false)" }

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
    end
  end
end
