# frozen_string_literal: true

module Zee
  module Generators
    class Mailer < Thor::Group
      include Thor::Actions
      using Core::String

      attr_accessor :options

      def self.source_root
        File.join(__dir__, "mailer")
      end

      def templates
        template "mailer.rb.erb", "app/mailers/#{basename}.rb"
        template "test.rb.erb", "test/mailers/#{basename}_test.rb"

        {
          "base.rb" => "app/mailers/base.rb",
          "layout.text.erb" => "app/views/layouts/mailer.text.erb",
          "layout.html.erb" => "app/views/layouts/mailer.html.erb"
        }.each do |from, to|
          next if File.file?(File.join(destination_root, to))

          copy_file from, to
        end

        options[:methods].each do |method|
          options[:current_method] = method
          template "text.erb", "app/views/#{basename}/#{method}.text.erb"
          template "html.erb", "app/views/#{basename}/#{method}.html.erb"
        end
      end

      no_commands do
        def mailer_class_name
          basename.camelize
        end

        def basename
          options[:name].underscore
        end
      end
    end
  end
end
