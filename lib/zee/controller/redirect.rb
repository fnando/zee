# frozen_string_literal: true

module Zee
  class Controller
    module Redirect
      # Redirect to a different location.
      # @param location [String] The location to redirect to.
      # @param status [Integer, Symbol] The status code of the response.
      # @param allow_other_host [Boolean] Allow redirects to other hosts.
      # @param options [Hash] Other options to set.
      # @option options [String] :notice Set a notice flash message.
      # @option options [String] :alert Set a alert flash message.
      # @option options [String] :info Set a info flash message.
      # @option options [String] :error Set a error flash message.
      # @raise [ArgumentError] If the location is empty.
      # @raise [UnsafeRedirectError] If the redirect is unsafe (i.e. trying to
      #                              redirect a different host without
      #                              setting `allow_other_host`).
      #
      # @example Redirect to the home page.
      #   redirect_to "/"
      #
      # @example Redirect to the home page with a 301 status.
      #   redirect_to "/", status: :moved_permanently
      #
      # @example Redirect to a different host.
      #   redirect_to "https://example.com", allow_other_host: true
      #
      # @example Redirect and set a flash message.
      #   redirect_to "/", notice: "Welcome back!"
      #   redirect_to "/", alert: "You need to activate your account."
      #   redirect_to "/", error: "Your account it's disabled."
      #   redirect_to "/", info: "Check your inbox."
      private def redirect_to(location, status: :found, allow_other_host: false,
                              **options)
        raise ArgumentError, "location cannot be empty" if location.to_s.empty?

        uri = URI(location)

        if uri.host && uri.host != request.host && !allow_other_host
          raise UnsafeRedirectError,
                "Unsafe redirect; " \
                "pass `allow_other_host: true` to redirect anyway."
        end

        # Set flash messages for redirect.
        flash_keys = %i[notice info alert error] & options.keys
        flash_keys.each {|key| flash[key] = options[key] }

        response.status(status)
        response.headers[:location] = location
        response.body = EMPTY_STRING
      end
    end
  end
end
