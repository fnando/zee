# frozen_string_literal: true

module Zee
  class Controller
    module AuthenticityToken
      CSRF_TOKEN = :_csrf_token

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

        expected = session[CSRF_TOKEN].to_s
        actual = if request.xhr?
                   request.get_header(HTTP_X_CSRF_TOKEN)
                 else
                   params[Controller.csrf_param_name]
                 end

        actual = actual.to_s
        renew_authenticity_token!

        valid = !expected.empty? &&
                !actual.empty? &&
                OpenSSL.secure_compare(expected, actual)

        return if valid

        render status: 422, text: "Invalid authenticity token"
      end

      # @private
      # Skip the authenticity token verification.
      # @return [Boolean]
      private def skip_authenticity_token_verification?
        request.get? || request.head?
      end

      # @!visibility public
      # Renew the authenticity token.
      # This method is called before every action.
      private def renew_authenticity_token!
        session[CSRF_TOKEN] = SecureRandom.hex(32)
      end

      # @!visibility public
      # The authenticity token.
      # @return [String]
      private def authenticity_token
        session[CSRF_TOKEN] ||= SecureRandom.hex(32)
      end
    end
  end
end
