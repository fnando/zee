# frozen_string_literal: true

require "rack/protection/content_security_policy"

module Zee
  module Middleware
    # Middleware to add a nonce to the Content-Security-Policy header.
    # This middleware extends [Rack::Protection::ContentSecurityPolicy](https://github.com/sinatra/sinatra/blob/main/rack-protection/lib/rack/protection/content_security_policy.rb)
    # to add a nonce.
    #
    # The nonce can be accessed from `request.env["zee.csp_nonce"]`.
    class ContentSecurityPolicy < Rack::Protection::ContentSecurityPolicy
      # @api private
      HEADER = "content-security-policy"

      def call(env)
        env[ZEE_CSP_NONCE] = SecureRandom.hex(16)

        status, headers, body = super

        csp = headers[HEADER]
        headers[HEADER] = "#{csp} 'nonce-#{env[ZEE_CSP_NONCE]}'"

        [status, headers, body]
      end
    end
  end
end
