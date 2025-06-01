# frozen_string_literal: true

AuthApp = Class.new(Zee::App).new
AuthApp.root = Pathname(__dir__)

AuthApp.routes do
  root to: "home#show"
  get "login", to: "login#new", as: "login"
  post "login", to: "login#create"
  get "dashboard", to: "dashboard#show", as: :dashboard
  get "metrics", to: "metrics#show", as: :metrics
end

AuthApp.config do
  set :logger, logger
  set :session_options, domain: "localhost", secure: false
end

AuthApp.initialize!
