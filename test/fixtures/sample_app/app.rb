# frozen_string_literal: true

class SampleApp < Zee::App
  def self.create
    app = new
    app.root = Pathname.new(__dir__)

    proc_app = lambda {|_env|
      [200, {"content-type" => "text/html"}, ["hello from rack app"]]
    }

    class_app = Class.new do
      def self.name
        "MyRackApp"
      end

      def self.call(_env)
        [200, {"content-type" => "text/html"}, ["hello from my app"]]
      end
    end

    redirect_app = ->(_env) { [302, {"location" => "/"}] }

    app.routes do
      root to: "pages#home"
      get "slim", to: "pages#slim"
      get "custom-layout", to: "pages#custom_layout"
      get "no-layout", to: "pages#no_layout"
      get "controller-layout", to: "things#show"
      get "missing-template", to: "pages#missing_template"
      get "hello", to: "pages#hello_ivar"
      get "text", to: "formats#text"
      get "html", to: "formats#html"
      get "to-html", to: "formats#html_protocol"
      get "xml", to: "formats#xml"
      get "to-xml", to: "formats#xml_protocol"
      get "json", to: "formats#json"
      get "locale", to: "locales#show"
      get "redirect", to: "pages#redirect"
      get "redirect-error", to: "pages#redirect_error"
      get "redirect-open", to: "pages#redirect_open"
      post "session", to: "sessions#create"
      get "session", to: "sessions#show"
      delete "session", to: "sessions#delete"
      get "helpers", to: "helpers#show"

      get "feed", to: "feeds#show"

      # Routes related to CSRF protection
      get "posts/new", to: "posts#new", as: :new_post
      post "posts/new", to: "posts#create"
      get "posts/:id", to: "posts#show", as: :post
      get "categories/new", to: "categories#new", as: :new_category
      post "categories/new", to: "categories#create"
      patch "categories/new", to: "categories#create"

      get "login", to: "login#new", as: :login
      get "messages", to: "messages#index", as: :messages
      post "messages", to: "messages#create"
      post "messages/set-keep", to: "messages#set_keep"
      post "messages/set-keep-all", to: "messages#set_keep_all"
      get "messages/keep", to: "messages#keep"
      get "messages/keep-all", to: "messages#keep_all"

      # Test namespaced controllers
      get "admin/posts", to: "admin/posts#index", as: :admin_posts

      # redirections
      redirect "old", to: "/"
      redirect "found", to: "/", status: :found
      redirect "redirect-rack-app", to: redirect_app

      mount proc_app, at: "proc-app", as: :proc_app
      mount class_app, at: "class-app", as: :class_app
    end

    app.config do
      set :session_options, domain: nil, secure: false
    end

    app.middleware do
      delete Rack::CommonLogger
      use Rack::ShowExceptions
    end

    Dir.chdir(app.root) { app.initialize! }

    app
  end
end
