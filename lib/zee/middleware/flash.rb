# frozen_string_literal: true

module Zee
  module Middleware
    # The flash middleware is responsible for removing flash messages that
    # must be discarded, and setting messages that will be discarded next.
    #
    # This middleware requires a session to work. If the session is not present,
    # it will skip the middleware and call the next middleware in the stack.
    class Flash
      def initialize(app)
        @app = app
      end

      def call(env)
        session = env[RACK_SESSION]
        return @app.call(env) unless session

        session[:flash] ||= {messages: {}, discard: []}
        flash = session[:flash]

        discard_now = flash[:discard]
        discard_next = flash[:messages].keys - discard_now

        discard_now.each {|key| flash[:messages].delete(key) }
        flash[:discard] = discard_next

        @app.call(env)
      end
    end
  end
end
