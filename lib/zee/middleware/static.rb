# frozen_string_literal: true

module Zee
  module Middleware
    class Static
      # @api private
      NOCACHE = "no-store, no-cache, max-age=0, must-revalidate"

      # @api private
      CACHE_CONTROL = "cache-control"

      # @api private
      SLASH_ASSETS = "/assets/"

      # @api private
      PATH_INFO = "PATH_INFO"

      # @api private
      REQUEST_METHOD = "REQUEST_METHOD"

      # @api private
      METHODS = %w[GET HEAD].freeze

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

        status, headers, body = *rack_app.call(env)

        if Zee.app.env.development? && env[PATH_INFO]&.start_with?(SLASH_ASSETS)
          headers = headers.merge(CACHE_CONTROL => NOCACHE)
        end

        [status, headers, body]
      end
    end
  end
end
