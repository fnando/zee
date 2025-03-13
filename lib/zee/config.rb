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
    # - `config.enable_reloading`: whether to enable code reloading.
    # - `config.logger`: a {Zee::Logger} instance that outputs to `$stdout`.
    # - `config.enable_instrumentation`: whether to enable request logging with
    #   better insights.
    # - `config.enable_template_caching`: whether to enable template caching.
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

    # @api private
    private def set_default_options
      set :logger,
          Logger.new(
            ::Logger.new($stdout),
            colorize: true,
            tag_color: :magenta,
            message_color: :cyan
          )
      set :domain, "localhost"
      set :default_url_options, {}
      set :session_options, secret: SecureRandom.hex(64)
      set :json_serializer, JSON
      set :template_handlers, %w[erb]
      set :serve_static_files, app&.env&.local?
      set :enable_reloading, false
      set :enable_template_caching, false
      set :enable_instrumentation, false
      set :filter_parameters, ParameterFilter::DEFAULT_FILTERS
    end

    # @api private
    def to_s
      "#<Zee::Config>"
    end
    alias inspect to_s

    # @api private
    def mandatory(*, **)
      super
    rescue SuperConfig::MissingEnvironmentVariable => error
      # :nocov:
      raise MissingEnvironmentVariable, error.message
      # :nocov:
    end

    # @api private
    def property(*, **, &)
      super
    rescue SuperConfig::MissingCallable
      raise MissingCallable,
            "arg[1] must respond to #call or a block must be provided"
    end

    # @api private
    def validate!(*)
      super
    rescue SuperConfig::MissingEnvironmentVariable => error
      raise MissingEnvironmentVariable, error.message
    end
  end
end
