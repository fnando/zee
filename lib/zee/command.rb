# frozen_string_literal: true

module Zee
  # @api private
  class Command < Thor
    check_unknown_options!

    # :nocov:
    def self.exit_on_failure?
      true
    end
    # :nocov:

    no_commands do
      def load_environment(env: :development, env_vars: true)
        if env_vars
          # :nocov:
          dotenvs = [".env.#{env}", ".env"]
          CLI.load_dotenv_files(*dotenvs)
          # :nocov:
        else
          ENV["ZEE_SILENT_CONFIG"] = "1"
        end

        require "./config/environment" if File.file?("./config/environment.rb")
        require "./config/config" if File.file?("./config/config.rb")
      end
    end
  end
end
