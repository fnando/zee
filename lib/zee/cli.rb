# frozen_string_literal: true

module Zee
  class CLI < Thor
    check_unknown_options!

    def self.exit_on_failure?
      true
    end

    desc "new PATH", "Create a new gem"
    def new(path)
      generator = Generator.new
      generator.destination_root = File.expand_path(path)
      generator.options = options
      generator.invoke_all
    end

    no_commands do
      # Add helper methods here
    end
  end
end
