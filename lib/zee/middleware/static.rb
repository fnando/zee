# frozen_string_literal: true

module Zee
  module Middleware
    class Static
      REQUEST_METHOD = "REQUEST_METHOD"
      METHODS = %w[GET HEAD].freeze
      ASSETS_DIRS = %r{/assets/(images|)}

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless METHODS.include?(env[REQUEST_METHOD])

        original_app = @app

        rack_app = Rack::Builder.app do
          use Rack::Static,
              root: "app",
              urls: ["/assets/images", "/assets/fonts"],
              cascade: true

          run Rack::Static.new(
            original_app,
            root: "public",
            urls: ["/"],
            cascade: true
          )
        end

        rack_app.call(env)
      end
    end
  end
end
