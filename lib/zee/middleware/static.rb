# frozen_string_literal: true

module Zee
  module Middleware
    class Static
      REQUEST_METHOD = "REQUEST_METHOD"
      METHODS = %w[GET HEAD].freeze

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless METHODS.include?(env[REQUEST_METHOD])

        static = Rack::Static.new(
          @app,
          root: "public",
          urls: ["/"],
          cascade: true
        )

        static.call(env)
      end
    end
  end
end
