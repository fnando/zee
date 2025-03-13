# frozen_string_literal: true

module Zee
  # Raised whenever trying to access the current app without setting it first.
  MissingAppError = Class.new(StandardError)

  class << self
    # The current app.
    # @return [Zee::App]
    attr_writer :app

    # The current app.
    # @return [Zee::App]
    # @raise [MissingAppError] If no app has been set.
    def app
      raise MissingAppError, "No app has been set to #{name}.app" unless @app

      @app
    end
  end

  # The error reporter.
  # @return [Zee::ErrorReporter]
  def self.error
    @error ||= ErrorReporter.new
  end

  # Set the error reporter.
  # @param error [Zee::ErrorReporter]
  def self.error=(error)
    @error = error
  end

  class App
    # This error is raised whenever the app is initialized more than once.
    AlreadyInitializedError = Class.new(StandardError)

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
      @init = []
      @root = Pathname.pwd
      self.env = compute_env
      instance_eval(&) if block_given?
    end

    # When `path` is set, defines the root directory of the application.
    # Always returns the root directory.
    #
    # @param path [String, Pathname]
    def root(path = nil)
      @root = Pathname(path) if path
      @root
    end

    # Alias for {#root}.
    # @param path [String, Pathname]
    def root=(path)
      root(path)
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
      @init ||= []
      @init << block if block
      @init
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
      @routes ||= Routes.new(config)
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

      run = block_given? &&
            (envs.map(&:to_sym).include?(env.to_sym) || envs.empty?)

      @config.instance_eval(&) if run

      @config
    end

    # Define the app's keyring. The keyring is used to encrypt and decrypt
    # secrets. By default, AES-256-GCM is used.
    #
    # The keyring must be a valid JSON string with the following format:
    #
    #     {"0": "<64 bytes>", "digest_salt": "<64 bytes>"}
    #
    # The secrets file is encrypted using the keyring.
    #
    # @see Zee::Keyring
    # @see Zee::MainKeyring
    # @see Zee::Secrets
    # @return [Zee::Keyring]
    def keyring
      @keyring ||= MainKeyring.read(env)
    end

    # Define the app's secrets. See {Zee::Secrets}.
    #
    # @return [Zee::Secrets]
    def secrets
      @secrets ||= Secrets.new(
        keyring:,
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

    # The default session options.
    # This is the default configuration for the session cookie:
    #
    # - `secret`: The session secret. Uses `config.secrets[:session_secret]` if
    #   available, or a random 32-chars long string otherwise.
    # - `path`: The path where the session cookie is available. Defaults to `/`.
    # - `same_site`: The SameSite attribute for the session cookie. Defaults to
    #   `:strict`.
    # - `expire_after`: The expiration time for the session cookie. Defaults to
    #   30 days.
    # - `http_only`: The HttpOnly attribute for the session cookie. Defaults to
    #   `true`.
    # - `secure`: The Secure attribute for the session cookie. Defaults to
    #   `true` in production, `false` otherwise.
    #
    # @return [Hash]
    def default_session_options
      secret = begin
        secrets[:session_secret]
      rescue MainKeyring::MissingKeyError
        SecureRandom.hex(32)
      end

      {
        key: ZEE_SESSION_KEY,
        path: SLASH,
        secret:,
        same_site: :strict,
        expire_after: 86_400 * 30, # 30 days
        http_only: true,
        secure: env.production?
      }
    end

    # The default middleware stack.
    # This is the stack that's included by default:
    #
    # - {https://github.com/rack/rack/blob/main/lib/rack/sendfile.rb Rack::Sendfile}
    # - {https://github.com/rack/rack/blob/main/lib/rack/runtime.rb Rack::Runtime}
    # - {https://github.com/sinatra/sinatra/tree/main/rack-protection Rack::Protection}
    #   (if available)
    # - {https://github.com/rack/rack-session Rack::Session::Cookie} (also see
    #   {#default_session_options})
    # - {https://github.com/rack/rack/blob/main/lib/rack/show_exceptions.rb Rack::ShowExceptions}
    #   (development only)
    # - {https://github.com/rack/rack/blob/main/lib/rack/head.rb Rack::Head}
    # - {https://github.com/rack/rack/blob/main/lib/rack/conditional_get.rb Rack::ConditionalGet}
    # - {https://github.com/rack/rack/blob/main/lib/rack/etag.rb Rack::ETag}
    # - {https://github.com/rack/rack/blob/main/lib/rack/tempfile_reaper.rb Rack::TempfileReaper}
    # - {https://github.com/rack/rack/blob/main/lib/rack/static.rb Rack::Static}
    #   (development only)
    # @return [Zee::MiddlewareStack]
    def default_middleware_stack
      MiddlewareStack.new(self).tap do |middleware|
        middleware.use Rack::ShowExceptions if env.development?
        middleware.use Middleware::RequestLogger
        middleware.use RequestStore::Middleware
        middleware.use Rack::Sendfile
        middleware.use Middleware::Static if config.serve_static_files
        middleware.use Rack::Runtime
        middleware.use Rack::Protection if defined?(Rack::Protection)

        if defined?(Rack::Session)
          middleware.use Rack::Session::Cookie,
                         default_session_options.merge(config.session_options)

          middleware.use Middleware::Flash
        end

        middleware.use Rack::Head
        middleware.use Rack::ConditionalGet
        middleware.use Rack::ETag
        middleware.use Rack::TempfileReaper
        middleware.use Middleware::ContentSecurityPolicy
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

      load_files
      run_init
      enable_reloading
      loader.setup
    end

    # @api private
    def run_init
      init.each { instance_eval(&_1) }
    end

    # @api private
    # Load the configuration files.
    # This is mostly used for reloading in development.
    # @param force [Boolean] If `true`, the files will be loaded using `load`
    #                        instead of `require`.
    # :nocov:
    def load_files(force: false)
      files = [root.join("config/config.rb"), root.join("config/routes.rb")]
      files += root.join("config/environments").glob("**/*.rb")
      files += root.join("config/initializers").glob("**/*.rb")

      files.each do |file|
        next unless file.file?

        if force
          load file
        else
          require file
        end
      end
    end
    # :nocov:

    # @api internal
    module BaseHelper
      using Core::Module
      internal_attr_reader :request, :controller, :current_template_path
    end

    # Set template helpers module.
    # @return [Module] The module to include.
    def helpers
      @helpers ||= begin
        app = self

        Module.new do
          helper_modules =
            ::Helpers.constants.map {|name| ::Helpers.const_get(name) }

          include(BaseHelper)
          include(ViewHelpers::Partial)
          include(ViewHelpers::Assets)
          include(ViewHelpers::Form)
          include(ViewHelpers::Link)
          include(ViewHelpers::MetaTag)
          include(ViewHelpers::Translation)
          include(app.routes.helpers)
          include(*helper_modules) if helper_modules.any?
        end
      end
    end

    # @api private
    def loader
      @loader ||= Zeitwerk::Loader.new
    end

    def call(env)
      if root == Dir.pwd
        # :nocov:
        to_app.call(env)
        # :nocov:
      else
        Dir.chdir(root) { to_app.call(env) }
      end
    end

    # Render a template.
    #
    # Every template will have the current template path injected
    # as `current_template_path`.
    #
    # @param file [String] The path to the template file.
    # @param locals [Hash] The variables to expose to the template.
    # @param context [Object] The context to evaluate the template in.
    # @param request [Zee::Request] The current request.
    # @param controller [Object, nil] The controller instance. Some helpers need
    #                                 it.
    # @yield The block to evaluate in the template.
    # @return [String] The rendered template.
    def render_template(
      file,
      locals: {},
      context: nil,
      controller: nil,
      request: nil,
      &
    )
      context ||= Object.new.extend(helpers)
      context.instance_variable_set(:@_controller, controller)
      context.instance_variable_set(:@_request, request)
      context.instance_variable_set(:@_current_template_path, Pathname(file))

      key = file.to_s
      template = template_cache[key]

      unless template
        options = {
          engine_class: Erubi::CaptureBlockEngine,
          freeze_template_literals: false,
          escape: true,
          bufval: BUFVAL,
          bufvar: BUFVAR
        }

        template = Tilt.new(file, options)
        template_cache[key] = template if config.enable_template_caching
      end

      template.render(context, locals, &)
    end

    # Keep compiled templates in memory.
    def template_cache
      @template_cache ||= {}
    end

    # @api private
    private def to_app
      @to_app ||= begin
        request_handler = RequestHandler.new(self)
        stack = middleware.to_a

        Rack::Builder.app do
          stack.each {|middleware, args, block| use(middleware, *args, &block) }
          run request_handler
        end
      end
    end

    # @api private
    private def compute_env
      env = ENV_NAMES.map { ENV[_1] }.compact.first.to_s

      env.empty? ? "development" : env
    end

    # :nocov:
    # @api private
    private def enable_reloading
      return unless config.enable_reloading

      require "listen"
      loader.enable_reloading
      only = Regexp.union(/\.(rb|yml\.enc)|Gemfile.lock$/, %r{public/assets})

      listener = Listen.to(root, only:) do
        @config = nil
        @routes = nil
        @secrets = nil
        @middleware = nil
        @to_app = nil
        @helpers = nil

        loader.reload
        load_files force: true
        run_init
      end

      listener.start
    rescue LoadError
      warn "Please add `gem 'listen'` to your Gemfile to enable reloading."
    end
    # :nocov:
  end
end
