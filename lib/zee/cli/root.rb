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

      require_relative "new"
      require_relative "routes"
      require_relative "console"
      require_relative "test" if CLI.available?("minitest")
      include Database if CLI.available?("sequel")
      include Secrets

      def self.handle_no_command_error(command, *)
        bin = "./bin/#{command}" unless command == "zee"

        return system(bin, *ARGV) if bin && File.exist?(bin)

        shell = Thor::Base.shell.new
        shell.say_error "ERROR: Could not find command `#{command}`.\n\n", :red
        help(shell)

        exit 1
      end

      map %w[--version] => :version
      desc "version, --version", "Print the version"
      def version
        puts "zee #{VERSION}"
      end

      desc "generate SUBCOMMAND", "Generate new code (alias: g)"
      subcommand "generate", Generate

      desc "assets", "Build assets"
      option :digest,
             type: :boolean,
             default: true,
             desc: "Enable asset digesting"
      option :prefix,
             type: :string,
             default: "/assets",
             desc: "The request path prefix"
      def assets
        bins = %w[bin/styles bin/scripts]

        FileUtils.rm_rf("public/assets")
        FileUtils.mkdir_p("public/assets")

        bins.each do |bin|
          bin = Pathname(bin)

          unless bin.file?
            raise Thor::Error,
                  set_color("ERROR: #{bin} not found", :red)
          end

          unless bin.executable?
            raise Thor::Error,
                  set_color("ERROR: #{bin} is not executable", :red)
          end

          # Export styles and scripts
          system(bin.to_s)
        end

        # Copy other assets
        Dir["./app/assets/*"].each do |dir|
          next if dir.end_with?("styles", "scripts")

          FileUtils.cp_r(dir, "public/assets/")
        end

        AssetsManifest.new(
          source: Pathname(Dir.pwd).join("public/assets"),
          digest: options[:digest],
          prefix: options[:prefix]
        ).call
      end

      no_commands do
        def db_helpers
          @db_helpers ||= Database::Helpers.new(options:, shell:)
        end

        # :nocov:
        def secrets_helpers
          @secrets_helpers ||= Secrets::Helpers.new(options:, shell:)
        end
        # :nocov:
      end
    end
  end
end
