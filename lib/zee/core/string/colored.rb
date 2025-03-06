# frozen_string_literal: true

module Zee
  module Core
    module String
      module Colored
        # @api private
        COLORS = {
          clear: "\e[0m",
          black: "\e[30m",
          red: "\e[31m",
          green: "\e[32m",
          yellow: "\e[33m",
          blue: "\e[34m",
          magenta: "\e[35m",
          cyan: "\e[36m",
          white: "\e[37m"
        }.freeze

        refine ::String do
          # Colorize a string.
          # @param color [Symbol]
          # @return [String]
          def colored(color)
            "#{COLORS[color]}#{self}#{COLORS[:clear]}"
          end
        end
      end
    end
  end
end
