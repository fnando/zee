# frozen_string_literal: true

class SampleApp < Zee::App
end

SampleAppInstance = SampleApp.new

Zee.app = SampleAppInstance

SampleAppInstance.routes do
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

  # Routes related to CSRF protection
  get "posts/new", to: "posts#new", as: :new_post
  post "posts/new", to: "posts#create"
  get "categories/new", to: "categories#new", as: :new_category
  post "categories/new", to: "categories#create"
  patch "categories/new", to: "categories#create"

  get "login", to: "login#new", as: :login

  proc_app = lambda {|_env|
    [200, {"content-type" => "text/html"}, ["hello from rack app"]]
  }
  mount proc_app, at: "proc-app", as: :proc_app

  class_app = Class.new do
    def self.name
      "MyRackApp"
    end

    def self.call(_env)
      [200, {"content-type" => "text/html"}, ["hello from my app"]]
    end
  end
  mount class_app, at: "class-app", as: :class_app
end

SampleAppInstance.middleware do
  delete Rack::CommonLogger
  use Rack::ShowExceptions
end

SampleAppInstance.initialize!
