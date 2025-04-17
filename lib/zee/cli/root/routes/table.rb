# frozen_string_literal: true

module Zee
  module CLI
    class Root < Command
      module Routes
        class Table
          def initialize(routes)
            @routes = routes
          end

          def render
            require "terminal-table"

            normalize_to = proc do |to|
              next to if to.is_a?(String)
              next to.name if to.respond_to?(:name)
              next to.to_s unless to.is_a?(Proc)

              path, line = to.source_location
              path = Pathname(path).relative_path_from(Dir.pwd)
              "#{path}:#{line}"
            end

            headings = %w[Verb Path Prefix To]
            rows = @routes.map do |route|
              [
                route.via.map { _1.to_s.upcase }.join(", "),
                route.path,
                route.name,
                normalize_to.call(route.to)
              ]
            end

            ::Terminal::Table.new(rows:, headings:) do |t|
              t.style = {
                border_left: false, border_right: false,
                padding_right: 5
              }
            end
          end
        end
      end
    end
  end
end
