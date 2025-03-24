# frozen_string_literal: true

module Zee
  module Generators
    class SystemTest < Thor::Group
      include Thor::Actions
      using Core::String

      attr_accessor :options

      def self.source_root
        File.join(__dir__, "system_test")
      end

      def templates
        template "test.rb.erb", "test/system/#{name}_test.rb"
      end

      no_commands do
        def name
          options[:name].underscore
        end

        def controller_class_name
          options[:name].camelize
        end
      end
    end
  end
end
