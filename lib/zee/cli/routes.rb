# frozen_string_literal: true

module Zee
  module CLI
    class Root < Command
      desc "routes", "List all routes"
      option :format,
             type: :string,
             aliases: "-f",
             default: "table",
             enum: %w[table typescript javascript]
      def routes
        load_environment

        case options[:format]
        when "typescript"
          puts Routes::TypeScript.new(Zee.app.routes.to_a).render.rstrip
        when "javascript"
          puts Routes::JavaScript.new(Zee.app.routes.to_a).render.rstrip
        else
          puts Routes::Table.new(Zee.app.routes.to_a).render
        end
      end
    end
  end
end
