# frozen_string_literal: true

module Zee
  class Controller
    include Renderer
    include Callbacks
    include AuthenticityToken
    include Locals
    include Flash
    using Zee::Core::Blank

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

    # Expose helper methods to templates.
    # With this method, you can expose helper methods to all actions.
    #
    # @see Locals#expose
    #
    # @example Expose a helper method to all actions.
    #   class ApplicationController < Zee::Controller
    #     expose :current_user, :user_logged_in?
    #
    #     private def current_user
    #       @current_user ||=
    #         Models::User.find(session[:user_id]) if session[:user_id]
    #     end
    #
    #     private def user_logged_in?
    #       current_user != nil
    #     end
    #   end
    def self.expose(*, **)
      before_action { expose(*, **) }
    end

    # @api private
    def self.inherited(subclass)
      super

      callbacks
        .each {|type, list| subclass.callbacks[type] = list.dup }

      skipped_callbacks
        .each {|type, list| subclass.skipped_callbacks[type] = list.dup }
    end

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
    # @return [Params]
    private def params
      @params ||= Params.new(request.params)
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

    # Define an object that inherits all the helpers from the application.
    # @return [Object]
    private def helpers
      @helpers ||= Object.new.extend(Zee.app.helpers).tap do |helpers|
        helpers.instance_variable_set(:@controller, self)
      end
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
        if response.status
          return instrument_before_action(name, callback, response)
        end
      end

      # If the action is missing, then raise an error.
      raise ArgumentError, ":action_name is not set" if action_name.empty?

      # Execute the action on the controller.
      public_send(action_name)

      # Run after action callbacks.
      self.class.callbacks[:after].each do |(callback, conditions)|
        instance_eval(&callback) if instance_eval(&conditions)
      end

      # If no status is set, then let's assume the action is implicitly
      # rendering the template.
      render(action_name) unless response.status
    end

    # @api private
    private def instrument_before_action(name, callback, response)
      return unless Zee.app.config.enable_instrumentation

      source = name
      source ||= begin
        file, line = callback.source_location
        [Pathname(file).relative_path_from(Dir.pwd), line].join(COLON)
      end

      props = {source: name ? ":#{name}" : source, scope: :before_action}
      location = response.headers[:location]
      props[:redirected_to] = location unless location.blank?

      instrument :request, **props
    end

    # @api private
    # The list of template source directories. By default, it only includes
    # you app's `app/views` directory.
    # @return [Array<Pathname>]
    def view_paths
      @view_paths ||= [Zee.app.root.join("app/views")]
    end
  end
end
