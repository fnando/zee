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
    # - `config.enable_reloading`: whether to enable code reloading.
    # - `config.logger`: a {Zee::Logger} instance that outputs to `$stdout`.
    # - `config.enable_instrumentation`: whether to enable request logging with
    #   better insights.
    # - `config.enable_template_caching`: whether to enable template caching.
    # - `config.cache`: the cache store.
    # - `config.inflector`: The app's inflector instance.
    # - `config.asset_host`: The app's asset host. Will be used when generating
    #   asset URLs.
    #
    # @param app [Zee::App] The application instance.
    # @param options [Hash{Symbol => Object}]
    # @return [Zee::Config]
    #
    # @example
    #   config = Zee::Config.new(app)
    # @param [Boolean] silent
    def initialize(
      app = nil,
      silent: !ENV.delete("ZEE_SILENT_CONFIG").nil?,
      **options
    )
      if silent
        options[:raise_exception] = false
        options[:stderr] = StringIO.new
      end

      @app = app
      block = proc { true }
      super(**options, &block)
      set_default_options
    end

    # @api private
    private def set_default_options
      dev = !!app&.env&.development? # rubocop:disable Style/DoubleNegation
      local = !!app&.env&.local? # rubocop:disable Style/DoubleNegation
      prod = !!app&.env&.production? # rubocop:disable Style/DoubleNegation

      set :logger,
          Logger.new(
            ::Logger.new($stdout),
            colorize: true,
            tag_color: :magenta,
            message_color: :cyan
          )
      set :allowed_hosts, ["localhost"]
      set :default_url_options, {}
      set :session_options, secret: SecureRandom.hex(64)
      set :json_serializer, JSON
      set :enable_reloading, false

      set :serve_static_files,
          env(:serve_static_files, local, type: :bool)

      set :enable_template_caching,
          env(:enable_template_caching, prod, type: :bool)

      set :enable_instrumentation,
          env(:enable_instrumentation, dev, type: :bool)

      set :asset_host, env(:asset_host, "", type: :string)

      set :handle_errors, env(:handle_errors, prod, type: :bool)

      set :filter_parameters, ParameterFilter::DEFAULT_FILTERS
      set :cache, CacheStore::Null.new(encrypt: false)
      set :inflector, Dry::Inflector.new
    end

    def env(name, default, type:)
      env_var = [:zee, name].join(UNDERSCORE).upcase
      return coerce(name, type, @env[env_var]) if @env.key?(env_var)

      default
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
