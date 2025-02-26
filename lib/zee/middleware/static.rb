# frozen_string_literal: true

module Zee
  module Middleware
    class Static
      NOCACHE = "no-store, no-cache, max-age=0, must-revalidate"
      CACHE_CONTROL = "cache-control"
      SLASH_ASSETS = "/assets/"
      PATH_INFO = "PATH_INFO"
      REQUEST_METHOD = "REQUEST_METHOD"
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
