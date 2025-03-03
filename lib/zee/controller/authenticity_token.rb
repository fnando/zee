# frozen_string_literal: true

module Zee
  class Controller
    module AuthenticityToken
      # @api private
      def self.included(base)
        base.before_action { renew_authenticity_token! if request.get? }
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

        expected = session[ZEE_CSRF_TOKEN].to_s
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

        unless expected.include?(DOUBLE_SLASH)
          return OpenSSL.secure_compare(expected, actual)
        end

        expected_token, _ = *expected.split(DOUBLE_SLASH)
        actual_token, actual_hmac = *actual.split(DOUBLE_SLASH)
        expected_hmac = create_authenticity_token_hmac(
          "#{request.request_method}#{request.path}#{expected_token}"
        )

        OpenSSL.secure_compare(expected_hmac, actual_hmac.to_s) &&
        OpenSSL.secure_compare(expected_token, actual_token.to_s)
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
        session[ZEE_CSRF_TOKEN] = SecureRandom.hex(32)
      end

      # @api private
      private def create_authenticity_token_hmac(input)
        OpenSSL::HMAC.hexdigest(
          OpenSSL::Digest.new("SHA256"),
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
          token = SecureRandom.hex(32)
          hmac = create_authenticity_token_hmac(
            "#{request_method.to_s.upcase}#{path}#{token}"
          )

          session[ZEE_CSRF_TOKEN] = "#{token}--#{hmac}"
        end

        session[ZEE_CSRF_TOKEN]
      end
    end
  end
end
