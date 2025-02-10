# frozen_string_literal: true

module Zee
  class Command < Thor
    check_unknown_options!

    # :nocov:
    def self.exit_on_failure?
      true
    end

    def self.before_run
      # noop
    end
    # :nocov:
  end
end
