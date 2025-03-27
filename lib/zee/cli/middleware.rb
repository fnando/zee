# frozen_string_literal: true

module Zee
  module CLI
    class Root < Command
      desc "middleware", "Displays the Rack middleware stack"
      option :environment,
             desc: "Environment to edit",
             type: :string,
             aliases: "-e",
             default: "development"
      option :with_arguments,
             desc: "Display middleware arguments",
             type: :boolean,
             default: false
      def middleware
        env = options[:environment]
        dotenvs = [".env.#{env}", ".env"]
        CLI.load_dotenv_files(*dotenvs)

        env_file = "./config/environment.rb"
        require env_file if File.file?(env_file)

        Zee.app.middleware.to_a.each do |(middleware, args, _)|
          shell.say middleware.inspect, :blue

          if options[:with_arguments] && args.any?
            shell.say "  #{args.join(', ')}", :yellow
          end
        end
      end
    end
  end
end
