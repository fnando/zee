# frozen_string_literal: true

module Zee
  module CLI
    class Root < Command
      map "c" => "console"
      desc "console", "Start a console (alias: c)"
      option :env,
             type: :string,
             default: "development",
             desc: "Set the environment",
             aliases: "-e",
             enum: %w[development test production]
      # :nocov:
      def console
        require "bundler/setup"
        require "dotenv"
        require "irb"
        require "irb/completion"

        env =
          (ENV_NAMES.filter_map do |name|
            ENV[name]
          end.first || options[:env]).to_sym

        Dotenv.load(".env", ".env.#{env}")
        Bundler.require(:default, env)
        require "./config/environment"

        prompt_prefix = "%N(#{set_color(PROMPT_ALIASES.fetch(env),
                                        PROMPT_COLORS.fetch(env))})"

        IRB.setup(nil)
        IRB.conf[:PROMPT][:ZEE] = {
          PROMPT_I: "#{prompt_prefix}> ",
          PROMPT_S: "#{prompt_prefix}%l ",
          PROMPT_C: "#{prompt_prefix}* ",
          RETURN: "=> %s\n"
        }
        IRB.conf[:PROMPT_MODE] = :ZEE
        IRB::Irb.new.run(IRB.conf)
      end
      # :nocov:
    end
  end
end
