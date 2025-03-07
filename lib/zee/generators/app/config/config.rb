# frozen_string_literal: true

Zee.app.config :development do
  # Enable code reloading.
  set :enable_reloading, true

  # Show better nicer logging for each request.
  set :enable_instrumentation, true
end

Zee.app.config :development, :test do
  # Set the domain that will be used for cookies.
  set :domain, "localhost"
end

Zee.app.config :production do
  # Set the domain that will be used for cookies.
  set :domain, "example.com"
end

Zee.app.config do
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
  set :session_options, domain:
end
