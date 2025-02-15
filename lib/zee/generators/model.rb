# frozen_string_literal: true

module Zee
  module Generators
    class Model < Thor::Group
      include Thor::Actions

      attr_accessor :options

      def self.source_root
        File.join(__dir__, "model")
      end

      def templates
        template "model.rb.erb", "app/models/#{options[:file_name]}.rb"
        template "test.rb.erb", "test/models/#{options[:file_name]}_test.rb"
      end
    end
  end
end
