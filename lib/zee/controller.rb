# frozen_string_literal: true

module Zee
  class Controller
    include Renderer
    include Redirect
    include Callbacks
    include AuthenticityToken
    include Locals
    include Flash
    include Translation
    include ErrorHandling
    using Zee::Core::Module

    # Raised when an trying to re-render an action, doing a redirect after
    # rendering, or even doing multiple redirection attempts.
    class DoubleRenderError < StandardError
      DEFAULT_MESSAGE =
        "Render/redirect called multiple times. You may only " \
        "render OR redirect once per action. Use `return` to exit early."

      def initialize(message = DEFAULT_MESSAGE)
        super
      end
    end

    # Raised when a template is missing.
    MissingTemplateError = Class.new(StandardError)

    # Raised when a redirect is unsafe.
    UnsafeRedirectError = Class.new(StandardError)

    # Raised when trying to expose a public method as a helper.
    UnsafeHelperError = Class.new(StandardError)

    # @api private
    # The template object.
    # @return [Struct]
    Template = Struct.new(:path, :mime, keyword_init: true)

    class << self
      # The CSRF parameter name.
      # Defaults to `_authenticity_token`.
      # @return [String]
      attr_accessor :csrf_param_name
    end

    self.csrf_param_name = :_authenticity_token

    # @api private

    # The current action name.
    # @return [String]
    internal_attr_reader :action_name

    # The current controller name.
    # @return [String]
    internal_attr_reader :controller_name

    # The current request.
    # @return [Zee::Request]
    internal_attr_reader :request

    # The current response.
    # @return [Zee::Response]
    internal_attr_reader :response

    # The parameters from the request.
    # @return [Params]
    internal_attr_reader :params

    def initialize(request:, response:, action_name: nil, controller_name: nil)
      @_request = request
      @_response = response
      @_action_name = action_name.to_s
      @_controller_name = controller_name.to_s
      @_params = Params.new(request.params)
    end

    # The session hash.
    private def session
      request.env[RACK_SESSION]
    end

    # Reset the session.
    private def reset_session
      session.clear
    end

    # Define an object that inherits all the helpers from the application.
    # @return [Object]
    private def helpers
      @_helpers ||= Object.new.extend(Zee.app.helpers)
    end

    # @api private
    # Run the action on the controller.
    # This will also run all callbacks defined by {#Callbacks#before_action}.
    #
    # @raise [MissingActionError] If the action is missing.
    # @raise [MissingTemplateError] If the template is missing.
    # @return [void]
    private def call
      # Run before action callbacks.
      self.class.callbacks[:before].each do |(callback, conditions, name)|
        instance_eval(&callback) if instance_eval(&conditions)

        # If the response is already set, then stop processing.
        if response.performed?
          return instrument_before_action(name, callback, response)
        end
      end

      # If the action is missing, then raise an error.
      raise ArgumentError, ":action_name is not set" if action_name.empty?

      # Execute the action on the controller.
      begin
        public_send(action_name)
      rescue Exception => error # rubocop:disable Lint/RescueException
        handle_action_error(error)
      end

      # Run after action callbacks.
      self.class.callbacks[:after].each do |(callback, conditions)|
        instance_eval(&callback) if instance_eval(&conditions)
      end

      # If no status is set, then let's assume the action is implicitly
      # rendering the template.
      render(action_name) unless response.performed?
    end

    # @api private
    # The list of template source directories. By default, it only includes
    # you app's `app/views` directory.
    # @return [Array<Pathname>]
    def view_paths
      @_view_paths ||= [Zee.app.root.join("app/views")]
    end

    # @api private
    def handle_action_error(error)
      response.reset

      self.class.rescue_handlers.reverse_each do |handler|
        matched = handler[:exceptions].any? { _1 === error } # rubocop:disable Style/CaseEquality
        instance_exec(error, &handler[:with]) if matched
      end

      return if response.status
      raise error unless Zee.app.config.handle_errors

      response.status(500)
      response.body = INTERNAL_SERVER_ERROR_MESSAGE
      response.headers[HTTP_CONTENT_TYPE] = TEXT_PLAIN
    end
  end
end
