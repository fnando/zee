# frozen_string_literal: true

module Zee
  module Middleware
    class Charset
      def initialize(app)
        @app = app
      end

      def call(env)
        status, headers, body = @app.call(env)
        content_type = headers[HTTP_CONTENT_TYPE]

        unless content_type&.include?(CHARSET)
          charset = Encoding.default_external.name
          content_type = "#{content_type}; charset=#{charset}"
          headers[HTTP_CONTENT_TYPE] = content_type
        end

        [status, headers, body]
      end
    end
  end
end
