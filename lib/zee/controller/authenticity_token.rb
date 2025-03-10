# frozen_string_literal: true

module Zee
  class Controller
    module AuthenticityToken
      SHA256 = "SHA256"

      # @api private
      def self.included(controller)
        controller.before_action { renew_authenticity_token! if request.get? }
      end

      # @!visibility public
      # Verify the authenticity token.
      # This method is called before every action.
      # It raises an error if the token is invalid.
      #
      # To skip the verification, you can use a `skip_before_action` call on
      # your controller, like `skip_before_action :verify_authenticity_token`.
      private def verify_authenticity_token
        return if skip_authenticity_token_verification?

        expected = session[CSRF_SESSION_KEY].to_s
        actual = if request.xhr?
                   request.get_header(HTTP_X_CSRF_TOKEN)
                 else
                   params[Controller.csrf_param_name]
                 end

        renew_authenticity_token!

        return if verified_authenticity_token?(expected.to_s, actual.to_s)

        render status: 422, text: "Invalid authenticity token"
      end

      # @api private
      # Verify the authenticity token.
      #
      # @param expected [String] The expected token.
      # @param actual [String] The actual token.
      # @return [Boolean]
      private def verified_authenticity_token?(expected, actual)
        return false if expected.empty? || actual.empty?
        return true if OpenSSL.secure_compare(expected, actual)

        expected_hmac = create_authenticity_token_hmac(
          "#{request.request_method}#{request.path}#{expected}"
        )

        OpenSSL.secure_compare(expected_hmac, actual.to_s)
      end

      # @api private
      # Skip the authenticity token verification.
      #
      # @return [Boolean]
      private def skip_authenticity_token_verification?
        request.get? || request.head?
      end

      # @!visibility public
      # Renew the authenticity token.
      # This method is called before every action.
      private def renew_authenticity_token!
        session[CSRF_SESSION_KEY] = SecureRandom.hex(32)
      end

      # @api private
      private def create_authenticity_token_hmac(input)
        OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new(SHA256),
          Zee.app.secrets[:session_secret],
          input
        )
      end

      # @!visibility public
      # The authenticity token.
      #
      # @param request_method [String] The request method.
      # @param path [String] The request path.
      # @return [String]
      private def authenticity_token(request_method: nil, path: nil)
        if request_method && path
          create_authenticity_token_hmac(
            "#{request_method.to_s.upcase}#{path}#{session[CSRF_SESSION_KEY]}"
          )
        else
          session[CSRF_SESSION_KEY]
        end
      end
    end
  end
end
