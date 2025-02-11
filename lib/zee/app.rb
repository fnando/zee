# frozen_string_literal: true

module Zee
  class App
    # This error is raised whenever the app is initialized more than once.
    AlreadyInitializedError = Class.new(StandardError)

    # The root path of the application.
    attr_accessor :root

    # The current environment. Defaults to "development".
    # It can be set using the following environment variables:
    #
    # - `ZEE_ENV`
    # - `APP_ENV`
    # - `RACK_ENV`
    #
    # @return [Zee::Environment]
    attr_reader :env

    def initialize(&)
      @initialized = false
      @on_init = []
      self.root = Pathname.pwd
      self.env = compute_env
      instance_eval(&) if block_given?
    end

    # Lazily evaluate a block only when the app is initialized.
    #
    # @example
    #   app.init do
    #     env.on(:development) do
    #       # do something only when the app is initialized
    #     end
    #   end
    def init(&block)
      @on_init << block
    end

    # Set the current environment.
    # @param env [String, Symbol]
    def env=(env)
      raise AlreadyInitializedError if initialized?

      @env = Environment.new(env)
    end

    # Define the app's routes. See {Zee::Routes}.
    #
    # @return [Zee::Routes]
    #
    # @example
    #   app.routes do
    #     root to: "pages#home"
    #   end
    def routes(&)
      @routes ||= Routes.new
      @routes.instance_eval(&) if block_given?
      @routes
    end

    # Define the app's configuration. See {Zee::Config}.
    #
    # @return [Zee::Config]
    #
    # @example Run config on every environment
    #   app.config do
    #     mandatory :database_url, string
    #   end
    #
    # @example Run config on every a specific environment
    #   app.config :development do
    #     set :domain, "example.dev"
    #   end
    #
    # @example Run config on every matching environment
    #   app.config :development, :test do
    #     set :domain, "example.dev"
    #   end
    def config(*envs, &)
      @config ||= Config.new(self)

      write = block_given? &&
              (envs.map(&:to_sym).include?(env.to_sym) || envs.empty?)

      @config.instance_eval(&) if write

      @config
    end

    # Define the app's secrets. See {Zee::Secrets}.
    #
    # @return [Zee::Secrets]
    def secrets
      @secrets ||= Secrets.new(
        key: MasterKey.read(env),
        secrets_file: root.join("config/secrets/#{env}.yml.enc")
      )
    end

    # Check if the app is initialized.
    # @return [Boolean]
    def initialized?
      @initialized
    end

    # Define the app's middleware stack.
    # See {Zee::App#default_middleware_stack}.
    # @return [Zee::MiddlewareStack]
    def middleware(&)
      @middleware ||= default_middleware_stack
      @middleware.instance_eval(&) if block_given?
      @middleware
    end

    # The default middleware stack.
    # This is the stack that's included by default:
    # - {https://github.com/rack/rack/blob/main/lib/rack/sendfile.rb Rack::Sendfile}
    # - {https://github.com/rack/rack/blob/main/lib/rack/runtime.rb Rack::Runtime}
    # - {https://github.com/rack/rack/blob/main/lib/rack/common_logger.rb Rack::CommonLogger}
    # - {https://github.com/sinatra/sinatra/tree/main/rack-protection Rack::Protection}
    # - {https://github.com/rack/rack-session Rack::Session::Cookie}
    # - {https://github.com/rack/rack/blob/main/lib/rack/show_exceptions.rb Rack::ShowExceptions}
    # - {https://github.com/rack/rack/blob/main/lib/rack/head.rb Rack::Head}
    # - {https://github.com/rack/rack/blob/main/lib/rack/conditional_get.rb Rack::ConditionalGet}
    # - {https://github.com/rack/rack/blob/main/lib/rack/etag.rb Rack::ETag}
    # - {https://github.com/rack/rack/blob/main/lib/rack/tempfile_reaper.rb Rack::TempfileReaper}
    # @return [Zee::MiddlewareStack]
    def default_middleware_stack
      MiddlewareStack.new.tap do |middleware|
        middleware.use Rack::Sendfile
        middleware.use Rack::Runtime
        middleware.use Rack::CommonLogger
        middleware.use Rack::Protection if defined?(Rack::Protection)

        if defined?(Rack::Session) && config.respond_to?(:session_options)
          middleware.use Rack::Session::Cookie, config.session_options
        end

        middleware.use Rack::ShowExceptions if env.development?
        middleware.use Rack::Head
        middleware.use Rack::ConditionalGet
        middleware.use Rack::ETag
        middleware.use Rack::TempfileReaper
      end
    end

    # Initialize the application.
    # This will load the necessary files and set up the application.
    # If a routes file exist at `config/routes.rb`, it will also be loaded.
    def initialize!
      raise AlreadyInitializedError if initialized?

      @initialized = true

      require "zeitwerk"
      Bundler.require(env.to_sym)

      Object.const_set(:Actions, Module.new) unless defined?(::Actions)
      Object.const_set(:Controllers, Module.new) unless defined?(::Controllers)
      Object.const_set(:Helpers, Module.new) unless defined?(::Helpers)
      Object.const_set(:Jobs, Module.new) unless defined?(::Jobs)
      Object.const_set(:Mailers, Module.new) unless defined?(::Mailers)
      Object.const_set(:Models, Module.new) unless defined?(::Models)
      Object.const_set(:Views, Module.new) unless defined?(::Views)

      push_dir = lambda do |dir, namespace|
        dir = root.join(dir)
        loader.push_dir(dir.to_s, namespace:) if dir.directory?
      end

      push_dir.call "app/actions", ::Actions
      push_dir.call "app/controllers", ::Controllers
      push_dir.call "app/helpers", ::Helpers
      push_dir.call "app/jobs", ::Jobs
      push_dir.call "app/mailers", ::Mailers
      push_dir.call "app/models", ::Models
      push_dir.call "app/views", ::Views

      instance_eval(&@on_init.shift) while @on_init.any?

      enable_reloading
      loader.setup

      routes_file = root.join("config/routes.rb")

      require routes_file if routes_file.file?
    end

    # @private
    def loader
      @loader ||= Zeitwerk::Loader.new
    end

    def call(env)
      env[RACK_ZEE_APP] = self
      Dir.chdir(root) { return app.call(env) }
    end

    private def app
      @app ||= begin
        request_handler = RequestHandler.new(self)
        stack = middleware.to_a

        Rack::Builder.app do
          stack.each {|middleware, args, block| use(middleware, *args, &block) }

          run request_handler
        end
      end
    end

    private def compute_env
      env = ENV_NAMES.map { ENV[_1] }.compact.first.to_s

      env.empty? ? "development" : env
    end

    # :nocov:
    private def enable_reloading
      return if env.development?

      require "listen"
      loader.enable_reloading
      only = /\.rb|Gemfile.lock$/
      listener = Listen.to(root, only:) { loader.reload }
      listener.start
    rescue LoadError
      warn "Please add `gem 'listen'` to your Gemfile to enable reloading."
    end
    # :nocov:
  end
end
