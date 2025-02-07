# frozen_string_literal: true

module Zee
  class Generator < Thor::Group
    include Thor::Actions

    attr_accessor :options

    def self.source_root
      File.join(__dir__, "templates")
    end

    no_commands do
      # Add helper methods here
    end
  end
end
