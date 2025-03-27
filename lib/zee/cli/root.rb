# frozen_string_literal: true

module Zee
  module CLI
    class Root < Command
      class_option :help,
                   type: :boolean,
                   aliases: "-h",
                   desc: "Display help information"

      # Override the default start method so we can show help for subcommands.
      def self.start(given_args = ARGV, config = {})
        help = given_args.include?("--help") || given_args.include?("-h")

        if help && given_args[0] != "help"
          command = given_args[0]
          super(["help", command], config)
        else
          super
        end
      end

      def self.handle_no_command_error(command, *)
        bin = "./bin/#{command}" unless command == "zee"

        return system(bin, *ARGV) if bin && File.exist?(bin)

        shell = Thor::Base.shell.new
        shell.say_error "ERROR: Could not find command `#{command}`.\n\n", :red
        help(shell)

        exit 1
      end

      require_relative "new"
      require_relative "routes"
      require_relative "console"
      require_relative "assets"
      require_relative "middleware"
      require_relative "test" if CLI.available?("minitest")

      map %w[--version] => :version
      desc "version, --version", "Print the version"
      def version
        puts "zee #{VERSION}"
      end

      map "g" => "generate"
      desc "generate SUBCOMMAND", "Generate new code (alias: g)"
      subcommand "generate", Generate

      desc "secrets SUBCOMMAND", "Manage secrets"
      subcommand "secrets", Secrets

      if CLI.available?("sequel")
        desc "db SUBCOMMAND", "Database commands"
        subcommand "db", Database
      end
    end
  end
end
