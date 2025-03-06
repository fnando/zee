# frozen_string_literal: true

module Zee
  module Middleware
    class RequestLogger
      using Zee::Core::Numeric
      using Zee::Core::String::Colored

      def initialize(app)
        @app = app
      end

      def call(env)
        request = Request.new(env)
        started = Time.new
        logger = Zee.app.config.logger

        logger.debug do
          "#{request.request_method} #{request.fullpath}".colored(:magenta)
        end

        response = @app.call(env)

        ended = Time.new
        duration = (ended - started).duration

        logger.debug do
          ["status:", response[0].to_s.colored(:yellow)].join(SPACE)
        end

        logger.debug do
          ["duration:", duration.colored(:yellow)].join(SPACE)
        end

        response
      end
    end
  end
end
