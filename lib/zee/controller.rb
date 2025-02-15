# frozen_string_literal: true

module Zee
  # Raised when a template is missing.
  MissingTemplateError = Class.new(StandardError)

  # Raised when a redirect is unsafe.
  UnsafeRedirectError = Class.new(StandardError)

  class Controller
    include Renderer

    # The current action name.
    # @return [String]
    attr_reader :action_name

    # The current controller name.
    # @return [String]
    attr_reader :controller_name

    # The current request.
    # @return [Zee::Request]
    attr_reader :request

    # The current response.
    # @return [Zee::Response]
    attr_reader :response

    def initialize(request:, response:, action_name: nil, controller_name: nil)
      @request = request
      @response = response
      @action_name = action_name
      @controller_name = controller_name
    end

    # The parameters from the request.
    # @return [Hash]
    def params
      request.params
    end

    # The variables that will be exposed to templates.
    # @return [Hash]
    #
    # @example
    #   locals[:name] = user.name
    def locals
      @locals ||= {}
    end

    # Expose variables to the template.
    # @param vars [Hash] The variables to expose.
    # @example
    #   expose message: "Hello, World!"
    def expose(**vars)
      locals.merge!(vars)
    end

    # The session hash.
    def session
      request.env[RACK_SESSION]
    end

    # Reset the session.
    def reset_session
      session.clear
    end

    # Redirect to a different location.
    # @param location [String] The location to redirect to.
    # @param status [Integer, Symbol] The status code of the response.
    # @param allow_other_host [Boolean] Allow redirects to other hosts.
    # @raise [ArgumentError] If the location is empty.
    # @raise [UnsafeRedirectError] If the redirect is unsafe (i.e. trying to
    #                              redirect a different host without
    #                              setting `allow_other_host`).
    # @example Redirect to the home page.
    #   redirect_to "/"
    # @example Redirect to the home page with a 301 status.
    #   redirect_to "/", status: :moved_permanently
    # @example Redirect to a different host.
    #   redirect_to "https://example.com", allow_other_host: true
    def redirect_to(location, status: :found, allow_other_host: false)
      raise ArgumentError, "location cannot be empty" if location.to_s.empty?

      uri = URI(location)

      if uri.host && uri.host != request.host && !allow_other_host
        raise UnsafeRedirectError,
              "Unsafe redirect; " \
              "pass `allow_other_host: true` to redirect anyway."
      end

      response.status(status)
      response.headers[:location] = location
      response.body = ""
    end
  end
end
