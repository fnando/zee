# frozen_string_literal: true

module Zee
  class App
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
      self.root = Pathname.pwd
      self.env = compute_env
      instance_eval(&) if block_given?
    end

    # Set the current environment.
    # @param env [String, Symbol]
    def env=(env)
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

    # Initialize the application.
    # This will load the necessary files and set up the application.
    # If a routes file exist at `config/routes.rb`, it will also be loaded.
    def initialize!
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

      enable_reloading
      loader.setup

      routes_file = root.join("config/routes.rb")

      require routes_file if routes_file.file?
    end

    # @private
    def loader
      @loader ||= Zeitwerk::Loader.new
    end

    def app
      @app ||= begin
        request_handler = RequestHandler.new(self)

        Rack::Builder.app do
          run request_handler
        end
      end
    end

    def call(env)
      env[RACK_ZEE_APP] = self
      Dir.chdir(root) { return app.call(env) }
    end

    private def compute_env
      env_name = ENV_NAMES.find { ENV[_1] } # rubocop:disable Style/FetchEnvVar
      env = ENV[env_name] if env_name # rubocop:disable Style/FetchEnvVar
      env = env.to_s

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
