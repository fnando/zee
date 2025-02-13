# frozen_string_literal: true

require_relative "boot"

App = Zee::App.new do
  config :development, :test do
    set :domain, "localhost"
  end

  config :production do
    set :domain, "example.com"
  end

  config do
    # You can connect to the database by setting an environment variable
    # `ENV["DATABASE_URL"]` or by using a .env file.
    # @example
    #   "postgres://localhost/myapp_development"
    # @example
    #   "sqlite://storage/development.db"
    # @example
    #   "mysql2://localhost/myapp_development"
    mandatory :database_url, string

    # Set the session options.
    # The session secret can be edited with `zee secrets:edit`.
    set :session_options,
        domain:,
        path: "/",
        expire_after: 86_400 * 30, # 30 days
        secret: app.secrets.session_secret,
        same_site: :strict,
        secure: app.env.production?,
        key: "_zee_session"
  end

  middleware do
    # Provides support for Cross-Origin Resource Sharing (CORS).
    # [https://github.com/cyu/rack-cors]
    # unshift Rack::Cors do
    #   allow do
    #     origins "*"
    #     resource "*", headers: :any, methods: %i[get post patch put]
    #   end
    # end

    # Protects against DNS rebinding and other Host header attacks.
    # [https://github.com/sinatra/sinatra/blob/main/rack-protection/lib/rack/protection/host_authorization.rb]
    use Rack::Protection::HostAuthorization,
        permitted_hosts: [app.config.domain],
        logging: false

    # Protects against protocol downgrade attacks and cookie hijacking.
    # [https://github.com/sinatra/sinatra/blob/main/rack-protection/lib/rack/protection/strict_transport.rb]
    use Rack::Protection::StrictTransport if app.env.production?

    # Protects against XSS attacks.
    # [https://github.com/sinatra/sinatra/blob/main/rack-protection/lib/rack/protection/content_security_policy.rb]
    use Rack::Protection::ContentSecurityPolicy

    # Protects against cookie tossing.
    # [https://github.com/sinatra/sinatra/blob/main/rack-protection/lib/rack/protection/cookie_tossing.rb]
    use Rack::Protection::CookieTossing

    # Protects against secret leakage and third party tracking.
    # [https://github.com/sinatra/sinatra/blob/main/rack-protection/lib/rack/protection/referrer_policy.rb]
    use Rack::Protection::ReferrerPolicy

    # Protects against CSRF.
    # If you're providing a public API, then you need to remove this middleware.
    # [https://github.com/sinatra/sinatra/blob/main/rack-protection/lib/rack/protection/remote_referrer.rb]
    use Rack::Protection::RemoteReferrer
  end

  init do
    # Connect to the database.
    Sequel.connect(config.database_url)

    # Enable logging.
    Sequel::Model.db.loggers << Logger.new($stdout) if env.development?

    # Enable plugin that sets timestamp columns.
    Sequel::Model.plugin :timestamps, update_on_create: true

    # Enable plugin that sets dirty columns.
    Sequel::Model.plugin :dirty

    # Enable plugin that sets json serializer.
    # @example
    #   User.first.to_json
    Sequel::Model.plugin :json_serializer

    # Enable plugin that strips leading and trailing whitespaces from strings.
    Sequel::Model.plugin :string_stripper

    # Enable plugin that adds SQL comments to queries.
    if env.development?
      Sequel::Model.db.extension(:sql_comments)
      Sequel::Model.plugin :sql_comments
    end

    # Set default values for columns.
    # @example
    #   class User < Sequel::Model
    #     default_values name: "Anonymous"
    #   end
    Sequel::Model.plugin :defaults_setter
  end
end
