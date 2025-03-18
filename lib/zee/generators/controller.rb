# frozen_string_literal: true

module Zee
  module Generators
    class Controller < Thor::Group
      include Thor::Actions
      using Core::String

      attr_accessor :options

      def self.source_root
        File.join(__dir__, "controller")
      end

      def templates
        template "controller.rb.erb", "app/controllers/#{options[:name]}.rb"
        template "test.rb.erb", "test/requests/#{options[:name]}_test.rb"

        options[:actions].each do |action|
          options[:current_action] = action
          template "action.html.erb",
                   "app/views/#{options[:name]}/#{action}.html.erb"
        end

        say_status "done", "You need define routes at config/routes.rb"
      end

      no_commands do
        def controller_class_name
          Dry::Inflector.new.camelize(options[:name])
        end
      end
    end
  end
end
