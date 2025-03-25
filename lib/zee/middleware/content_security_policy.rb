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

      # @api private
      REPORT_HEADER = "content-security-policy-report-only"

      # @api private
      SEMICOLON = ";"

      def call(env)
        header_name = options[:report_only] ? REPORT_HEADER : HEADER
        env[ZEE_CSP_NONCE] = SecureRandom.hex(16)

        status, headers, body = super

        csp = headers.fetch(header_name, "").split(SEMICOLON).map do |part|
          "#{part} 'nonce-#{env[ZEE_CSP_NONCE]}'"
        end
        headers[header_name] = csp.join(SEMICOLON)

        [status, headers, body]
      end
    end
  end
end
