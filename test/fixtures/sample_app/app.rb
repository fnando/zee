# frozen_string_literal: true

SampleApp = Zee::App.new do
  root Pathname(__dir__)

  routes do
    root to: "pages#home"
    get "custom-layout", to: "pages#custom_layout"
    get "no-layout", to: "pages#no_layout"
    get "controller-layout", to: "things#show"
    get "missing-template", to: "pages#missing_template"
    get "hello", to: "pages#hello"
    get "text", to: "formats#text"
    get "json", to: "formats#json"
    get "redirect", to: "pages#redirect"
    get "redirect-error", to: "pages#redirect_error"
    get "redirect-open", to: "pages#redirect_open"
    post "session", to: "sessions#create"
    get "session", to: "sessions#show"
    delete "session", to: "sessions#delete"
    get "helpers", to: "helpers#show"

    get "posts/new", to: "posts#new", as: :new_post
    post "posts/new", to: "posts#create", as: :posts
  end

  middleware do
    delete Rack::CommonLogger
  end
end

SampleApp.initialize!
