# frozen_string_literal: true

Zee.app.middleware do
  # Provides support for Cross-Origin Resource Sharing (CORS).
  # [https://github.com/cyu/rack-cors]
  # unshift Rack::Cors do
  #   allow do
  #     origins "*"
  #     resource "*", headers: :any, methods: %i[get post patch put]
  #   end
  # end

  # Protect against typical web attacks.
  # If you're using OmniAuth, you need to use `except: [:remote_token]`.
  # [https://github.com/sinatra/sinatra]
  use Rack::Protection

  # Protects against DNS rebinding and other Host header attacks.
  # [https://github.com/sinatra/sinatra/blob/main/rack-protection/lib/rack/protection/host_authorization.rb]
  use Rack::Protection::HostAuthorization,
      permitted_hosts: app.config.allowed_hosts,
      logging: false

  # Protects against protocol downgrade attacks and cookie hijacking.
  # [https://github.com/sinatra/sinatra/blob/main/rack-protection/lib/rack/protection/strict_transport.rb]
  use Rack::Protection::StrictTransport if app.env.production?

  # Use common logger in production.
  # [https://github.com/rack/rack/blob/main/lib/rack/common_logger.rb]
  use Rack::CommonLogger if app.env.production?

  # Enable compression of HTTP responses.
  # [https://github.com/rack/rack/blob/main/lib/rack/deflater.rb]
  use Rack::Deflater if app.env.production?

  # Protects against XSS attacks.
  use Zee::Middleware::ContentSecurityPolicy, {
    default_src: "'self'",
    img_src: "'self' data:"
  }

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
