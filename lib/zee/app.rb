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
      @keyring ||= Keyring.load(root.join("config/secrets/#{env}.key"))
    end

    # Define the app's secrets. See {Zee::Secrets}.
    #
    # @return [Zee::Secrets]
    def secrets
      @secrets ||= Secrets.new(
        keyring:,
        secrets_file: ENV.fetch(
          ZEE_SECRETS_FILE,
          root.join("config/secrets/#{env}.yml.enc")
        )
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
      rescue Keyring::MissingKeyError
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
      @default_middleware_stack ||=
        MiddlewareStack.new(self).tap do |middleware|
          middleware.use Rack::Runtime
          middleware.use Middleware::Charset
          middleware.use RequestStore::Middleware
          middleware.use Rack::ShowExceptions if env.development?
          middleware.use Middleware::Static if config.serve_static_files?
          middleware.use Middleware::RequestLogger
          middleware.use Rack::Sendfile

          if defined?(Rack::Session)
            middleware.use Rack::Session::Cookie,
                           default_session_options.merge(config.session_options)

            middleware.use Middleware::Flash
          end

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

      push_dir = lambda do |dir|
        namespace = config.inflector.camelize(File.basename(dir)).to_sym
        dir = root.join(dir)
        next unless dir.directory?

        namespace = if Object.const_defined?(namespace)
                      Object.const_get(namespace)
                    else
                      Object.const_set(namespace, Module.new)
                    end

        loader.push_dir(dir.to_s, namespace:)
      end

      root.join("app").glob("*").each do |dir|
        next unless dir.directory?

        push_dir.call("app/#{dir.basename}")
      end

      $LOAD_PATH << root.join("lib").to_s
      loader.push_dir("lib") if root.join("lib").directory?

      init { set_i18n_load_path }

      load_files
      run_init
      enable_reloading
      loader.setup
      loader.eager_load if env.production?
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

    # @api private
    module BaseHelper
      using Core::Module
      internal_attr_reader :request, :controller, :current_template
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
          include(ViewHelpers::Assets)
          include(ViewHelpers::Form)
          include(ViewHelpers::Link)
          include(ViewHelpers::MetaTag)
          include(ViewHelpers::Translation)
          include(ViewHelpers::Caching)
          include(Controller::Flash::Helpers)
          include(app.routes.helpers)
          include(*helper_modules) if helper_modules.any?
        end
      end
    end

    # @api private
    def loader
      @loader ||= Zeitwerk::Loader.new
    end

    # @api private
    # The list of template source directories. By default, it only includes
    # you app's `app/views` directory.
    # @return [Array<Pathname>]
    def view_paths
      @view_paths ||= [root.join("app/views")]
    end

    def call(env)
      if root == Pathname.pwd
        # :nocov:
        to_app.call(env)
        # :nocov:
      else
        Dir.chdir(root) { to_app.call(env) }
      end
    end

    # @!method render_template(file, **options, &block)
    # Render a template.
    #
    # Every template will have the current template injected
    # as `current_template`.
    #
    # @param file [String] The path to the template file.
    # @param options [Hash] The rendering options.
    # @option options [Hash] locals The variables to expose to the template. If
    #                               they're prefixed with `@`, they will be
    #                               defined as instance variables.
    # @option options [Object] context The context to evaluate the template in.
    # @option options [Zee::Request] request The current request.
    # @option options [Object, nil] controller The controller instance. Some
    #                                          helpers need it.
    # @yield The block to evaluate in the template.
    # @return [String] The rendered template.
    def render_template(file, **options, &) # rubocop:disable Style/ArgumentsForwarding
      Template.render(
        file,
        helpers:,
        cache: config.enable_template_caching?,
        **options, # rubocop:disable Style/ArgumentsForwarding
        &
      )
    end

    # @api private
    private def to_app
      @to_app ||= begin
        request_handler = RequestHandler.new(self)
        stack = middleware.to_a

        Rack::Builder.app do
          stack.each do |middleware, args, kwargs, block|
            use(middleware, *args, **kwargs, &block)
          end

          run request_handler
        end
      end
    end

    # @api private
    private def compute_env
      env = ENV_NAMES.map { ENV[_1] }.compact.first.to_s

      env.empty? ? "development" : env
    end

    # @api private
    def set_i18n_load_path
      paths = I18n.load_path
      paths += root.join("config/locales").glob("**/*.{yml,rb}")
      paths = paths.filter_map do |path|
        path = Pathname(path).expand_path
        path.to_s if path.file?
      end

      I18n.load_path = paths.uniq
    end

    # :nocov:
    # @api private
    private def enable_reloading
      return unless config.enable_reloading?

      require "listen"
      loader.enable_reloading
      only = Regexp.union(
        /\.(rb|enc|ya?ml)$/,
        %r{public/assets},
        /Gemfile\.lock$/
      )
      ignore = Regexp.union(
        /node_modules/,
        /\.git/,
        /public/,
        /tmp/,
        /log/,
        /storage/,
        /db/,
        /bin/
      )

      listener = Listen.to(root, only:, ignore:) do
        skip_reset = %i[@init @initialized @root @loader @env]

        instance_variables.each do |var|
          next if skip_reset.include?(var)

          instance_variable_set(var, nil)
        end

        loader.reload
        load_files force: true
        run_init

        if defined?(Sequel)
          Sequel::DATABASES.each do |db|
            db.tables.each {|table| db.schema(table, reload: true) }
          end
        end

        I18n.reload!
        I18n.t("reload", default: "reload")
      end

      listener.start
    rescue LoadError
      warn "Please add `gem 'listen'` to your Gemfile to enable reloading."
    end
    # :nocov:
  end
end
