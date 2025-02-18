# frozen_string_literal: true

module Zee
  # The configuration for the application.
  # It uses {https://rubygems.org/gems/superconfig SuperConfig} to define the
  # configuration.
  class Config < SuperConfig::Base
    MissingEnvironmentVariable = Class.new(StandardError)
    MissingCallable = Class.new(StandardError)

    undef_method :credential

    # The application instance.
    # @return [Zee::App]
    attr_reader :app

    # Initialize the configuration.
    # It sets the following default options:
    #
    # - `config.default_url_options`: the default URL options.
    # - `config.session_options`: the session cookie options.
    # - `config.json_serializer`: the default JSON serializer.
    # - `config.template_handlers`: the list of template handlers that are
    #    enabled by {https://github.com/jeremyevans/tilt Tilt}.
    #
    # @param app [Zee::App] The application instance.
    # @return [Zee::Config]
    #
    # @example
    #   config = Zee::Config.new(app)
    def initialize(app = nil, **)
      @app = app
      block = proc { true }
      super(**, &block)
      set_default_options
    end

    private def set_default_options
      set :default_url_options, {}
      set :session_options, secret: SecureRandom.hex(64)
      set :json_serializer, JSON
      set :template_handlers, %w[erb]
      set :serve_static_files, app&.env&.local?
    end

    # @private
    def to_s
      "#<Zee::Config>"
    end
    alias inspect to_s

    # @private
    def mandatory(*, **)
      super
    rescue SuperConfig::MissingEnvironmentVariable => error
      # :nocov:
      raise MissingEnvironmentVariable, error.message
      # :nocov:
    end

    # @private
    def property(*, **, &)
      super
    rescue SuperConfig::MissingCallable
      raise MissingCallable,
            "arg[1] must respond to #call or a block must be provided"
    end

    # @private
    def validate!(*)
      super
    rescue SuperConfig::MissingEnvironmentVariable => error
      raise MissingEnvironmentVariable, error.message
    end
  end
end
