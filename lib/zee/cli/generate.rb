# frozen_string_literal: true

module Zee
  class CLI < Thor
    class Generate < Thor
      desc "generate SUBCOMMAND", "Generate new code"

      option :name, type: :string,
                    required: true,
                    desc: "Generate a new migration",
                    aliases: "-n"
      def migration
        generator = Generators::Migration.new
        generator.destination_root = File.expand_path(Dir.pwd)
        generator.options = options
        generator.invoke_all
      end

      no_commands do
        # helpers
      end
    end
  end
end
