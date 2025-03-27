# frozen_string_literal: true

module Zee
  module CLI
    class Root < Command
      desc "routes", "List all routes"
      def routes
        require "bundler/setup"
        require "dotenv"
        require "terminal-table"

        Dotenv.load(".env", ".env.development", ".env.test", ".env.production")
        Bundler.require(:default)
        require "./config/environment" if File.file?("./config/environment.rb")

        normalize_to = proc do |to|
          next to if to.is_a?(String)
          next to.name if to.respond_to?(:name)
          next to.to_s unless to.is_a?(Proc)

          path, line = to.source_location
          path = Pathname(path).relative_path_from(Dir.pwd)
          "#{path}:#{line}"
        end

        routes = Zee.app.routes.to_a
        headings = %w[Verb Path Prefix To]
        rows = routes.map do |route|
          [
            route.via.map { _1.to_s.upcase }.join(", "),
            route.path,
            route.name,
            normalize_to.call(route.to)
          ]
        end

        table = ::Terminal::Table.new(rows:, headings:) do |t|
          t.style = {border_left: false, border_right: false, padding_right: 5}
        end

        puts table
      end
    end
  end
end
