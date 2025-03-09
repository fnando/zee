# frozen_string_literal: true

module Zee
  module Middleware
    class Flash
      def initialize(app)
        @app = app
      end

      def call(env)
        env[RACK_SESSION][:flash] ||= {messages: {}, discard: []}
        flash = env[RACK_SESSION][:flash]

        discard_now = flash[:discard]
        discard_next = flash[:messages].keys - discard_now

        discard_now.each {|key| flash[:messages].delete(key) }
        flash[:discard] = discard_next

        @app.call(env)
      end
    end
  end
end
