# frozen_string_literal: true

module Zee
  module CLI
    class Root < Command
      desc "new PATH", "Create a new app"
      option :skip_bundle, type: :boolean,
                           default: false,
                           desc: "Skip bundle install",
                           aliases: "-B"
      option :skip_npm, type: :boolean,
                        default: false,
                        desc: "Skip npm install",
                        aliases: "-N"
      option :database, type: :string,
                        default: "sqlite",
                        desc: "Set the database",
                        aliases: "-d",
                        enum: %w[sqlite postgresql mysql mariadb]
      option :css,
             type: :string,
             default: "tailwind",
             enum: %w[tailwind],
             desc: "Use a CSS framework"
      option :js,
             type: :string,
             default: "typescript",
             enum: %w[js typescript],
             desc: "Use a JavaScript language"
      option :test,
             type: :string,
             default: "minitest",
             enum: %w[minitest rspec],
             desc: "Use a test framework"
      option :template,
             type: :string,
             desc: "Path to some application template (can be a filesystem " \
                   "path or URL)"
      def new(path)
        generator = Generators::App.new
        generator.destination_root = File.expand_path(path)
        generator.options = options
        generator.invoke_all

        say "\n==========", :red
        say "Important!", :red
        say "==========", :red
        say "We generated encryption keys at config/secrets/*.key"
        say "Save this in a password manager your team can access."
        say "Without the key, no one, including you, " \
            "can access the encrypted credentiails."

        say "\nTo start the app, run:"
        say "  bin/zee dev"
      end
    end
  end
end
