# frozen_string_literal: true

module Zee
  class CLI < Command
    class Helpers
      extend Forwardable

      attr_reader :options, :shell

      def_delegators :shell, :say, :say_status, :say_error, :set_color

      def initialize(options:, shell:)
        @options = options
        @shell = shell
      end
    end
  end
end
