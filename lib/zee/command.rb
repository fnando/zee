# frozen_string_literal: true

module Zee
  class Command < Thor
    check_unknown_options!

    # :nocov:
    def self.exit_on_failure?
      true
    end
    # :nocov:
  end
end
