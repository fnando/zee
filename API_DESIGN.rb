# config/app.rb
MyApp = App.new do
  # Can be inline or defined on config/routes.rb
  routes do
    root "pages#home"

    subdomain("api") do
      resources :posts
    end
  end

  # Can be inline or defined on config/middleware.rb
  middleware.use Something

  # Can be inline or defined on config/config.rb
  config do
    mandatory :database_url, string
    optional :tz, string, "Etc/UTC"

    # Fetched from encrypted file like
    # config/secrets/:env.enc
    secret :some_api_key
  end
end

module Helpers
  # app/helpers/numbers.rb
  module Numbers
    def number_to_currency(*)
    end
  end
end

module Controllers
  # app/controllers/base.rb
  class Base < App::Controller
    layout :application
  end

  # app/controllers/posts.rb
  class Posts < Base
    before_action :require_logged_user

    def index
      render json: Models::Post.all
    end
  end

  # app/controllers/pages.rb
  class Pages < Base
    def home
      # will define a template variable
      expose :title, "Welcome"

      render
    end
  end
end

module Models
  # app/models/base.rb
  class Base < Sequel::Model
  end

  # app/models/post.rb
  class Post < Base
  end
end

# config.ru
require_relative "config/app"
MyApp.initialize!
run MyApp
