# frozen_string_literal: true

module Zee
  class Controller
    # Raised when a template is missing.
    MissingTemplateError = Class.new(StandardError)

    # Raised when a redirect is unsafe.
    UnsafeRedirectError = Class.new(StandardError)

    # Raised when trying to expose a public method as a helper.
    UnsafeHelperError = Class.new(StandardError)

    include Renderer
    extend Callbacks

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
      @action_name = action_name.to_s
      @controller_name = controller_name.to_s
    end

    # The parameters from the request.
    # @return [Hash]
    private def params
      request.params
    end

    # The variables that will be exposed to templates.
    # @return [Hash]
    #
    # @example
    #   locals[:name] = user.name
    private def locals
      @locals ||= {}
    end

    # Expose variables and methods to the template.
    # @param helper_names [Array<Symbol>] The helper methods to expose. Notice
    #                                     that methods must be private.
    # @param vars [Hash] The variables to expose.
    # @example Expose a message to the template.
    #   expose message: "Hello, World!"
    # @example Expose a helper method to the template.
    #   expose :say_hello
    private def expose(*helper_names, **vars)
      helper_names.each do |name|
        if self.class.public_method_defined?(name)
          raise UnsafeHelperError, "#{name.inspect} must be a private method"
        end

        ref = method(name)

        helpers.instance_eval do
          define_method(name) do |*args, **kwargs, &block|
            ref.call(*args, **kwargs, &block)
          end
        end
      end

      locals.merge!(vars)
    end

    # Set template helpers.
    # @return [Module] The module to include.
    private def helpers
      @helpers ||= Module.new.tap do |target|
        helpers = Module.new

        ::Helpers.constants.each do |name|
          helpers.include(::Helpers.const_get(name))
        end

        target.include(helpers)
      end
    end

    # The session hash.
    private def session
      request.env[RACK_SESSION]
    end

    # Reset the session.
    private def reset_session
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
    private def redirect_to(location, status: :found, allow_other_host: false)
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

    # @private
    # Run the action on the controller.
    # This will also run all callbacks defined by {#before_action}.
    # @param action_name [String] The name of the action to run.
    # @raise [MissingActionError] If the action is missing.
    # @raise [MissingTemplateError] If the template is missing.
    #
    # @example Run the show action.
    #   call("show")
    private def call
      # Run before action callbacks.
      self.class.before_action_callbacks.each do |(callback, conditions)|
        instance_eval(&callback) if conditions.all? { instance_eval(&_1) }

        # If the response is already set, then stop processing.
        return true if response.status
      end

      # If the action is missing, then raise an error.
      raise ArgumentError, ":action_name is not set" if action_name.empty?

      # Execute the action on the controller.
      public_send(action_name)

      # If no status is set, then let's assume the action is implicitly
      # rendering the template.
      render(action_name) unless response.status
    end
  end
end
