# frozen_string_literal: true

module Zee
  class Controller
    include Renderer
    include Redirect
    include Callbacks
    include AuthenticityToken
    include HelperMethods
    include Flash::Helpers
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

    # Raised when a controller action is missing.
    MissingActionError = Class.new(StandardError)

    # Raised when a template is missing.
    MissingTemplateError = Class.new(StandardError)

    # Raised when a redirect is unsafe.
    UnsafeRedirectError = Class.new(StandardError)

    # Raised when trying to expose a public method as a helper.
    UnsafeHelperError = Class.new(StandardError)

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
      @_controller = self
      @_params = Params.new(request.params)
    end

    helper_methods :session, :params
    private :params

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
      Zee.error.context[:controller_class] = self.class.name
      Zee.error.context[:controller_name] = controller_name
      Zee.error.context[:action_name] = action_name

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

      # If the action is not defined, raise an error.
      unless respond_to?(action_name)
        raise MissingActionError,
              "action #{controller_name}##{action_name} is not defined."
      end

      # Define helper methods.
      define_helper_methods

      # Set a copy of the request parameters in the environment, because it
      # includes route parameters.
      request.env[ZEE_PARAMS] = params.to_h

      # Execute the action on the controller.
      public_send(action_name)

      # If no status is set, then let's assume the action is implicitly
      # rendering the template.
      render(action_name) unless response.performed?

      # Run after action callbacks.
      self.class.callbacks[:after].each do |(callback, conditions)|
        instance_eval(&callback) if instance_eval(&conditions)
      end
    rescue Exception => error # rubocop:disable Lint/RescueException
      handle_action_error(error)
    end

    # @api private
    def define_helper_methods
      self.class.helper_method.each do |name|
        if self.class.public_method_defined?(name)
          raise UnsafeHelperError,
                "#{name.inspect} must be a private method"
        end

        ref = method(name)
        file, line = ref.source_location

        helpers.instance_eval <<~RUBY, file, line + 1 # rubocop:disable Style/EvalWithLocation
          def #{name}(*, **)                          # def hello(*, **)
            controller.send(:"#{name}", *, **)        #  controller.send(:hello, *, **)
          end                                         # end
        RUBY
      end
    end

    # @api private
    # The list of template source directories. By default, it returns
    # {App#view_paths}.
    # @return [Array<Pathname>]
    def view_paths
      Zee.app.view_paths
    end

    # @api private
    def handle_action_error(error)
      Zee.error.report(error)
      previously_performed = response.performed?

      self.class.rescue_handlers.reverse_each do |handler|
        matched = handler[:exceptions].any? { _1 === error } # rubocop:disable Style/CaseEquality
        instance_exec(error, &handler[:with]) if matched
      rescue Exception => error # rubocop:disable Lint/RescueException
        Zee.error.report(error)
      end

      return if !previously_performed && response.performed?
      raise error unless Zee.app.config.handle_errors?

      response.reset
      response.status(:internal_server_error)
      response.body = INTERNAL_SERVER_ERROR_MESSAGE
      response.headers[HTTP_CONTENT_TYPE] = TEXT_PLAIN
    end
  end
end
