# frozen_string_literal: true

require "test_helper"

class RoutesTest < Minitest::Test
  test "defines root route" do
    routes = Zee::Routes.new do
      root to: "home#index"
    end

    route = routes.find(
      Zee::Request.new("REQUEST_METHOD" => "GET", "PATH_INFO" => "/")
    )

    refute_nil route
    assert_equal :root, route.as
  end

  test "defines GET route" do
    routes = Zee::Routes.new do
      get "posts", to: "posts#index"
    end

    route = routes.find(
      Zee::Request.new("REQUEST_METHOD" => "GET", "PATH_INFO" => "/posts")
    )

    refute_nil route
  end

  test "defines POST route" do
    routes = Zee::Routes.new do
      post "posts", to: "posts#create"
    end

    route = routes.find(
      Zee::Request.new("REQUEST_METHOD" => "POST", "PATH_INFO" => "/posts")
    )

    refute_nil route
  end

  test "defines PATCH route" do
    routes = Zee::Routes.new do
      patch "posts/:id", to: "posts#update"
    end

    route = routes.find(
      Zee::Request.new("REQUEST_METHOD" => "PATCH", "PATH_INFO" => "/posts/1")
    )

    refute_nil route
  end

  test "defines PUT route" do
    routes = Zee::Routes.new do
      put "posts/:id", to: "posts#update"
    end

    route = routes.find(
      Zee::Request.new("REQUEST_METHOD" => "PUT", "PATH_INFO" => "/posts/1")
    )

    refute_nil route
  end

  test "defines DELETE route" do
    routes = Zee::Routes.new do
      delete "posts/:id", to: "posts#destroy"
    end

    route = routes.find(
      Zee::Request.new("REQUEST_METHOD" => "DELETE", "PATH_INFO" => "/posts/1")
    )

    refute_nil route
  end

  test "defines OPTIONS route" do
    routes = Zee::Routes.new do
      options "posts/:id", to: "posts#options"
    end

    route = routes.find(
      Zee::Request.new("REQUEST_METHOD" => "OPTIONS", "PATH_INFO" => "/posts/1")
    )

    refute_nil route
  end

  test "defines HEAD route" do
    routes = Zee::Routes.new do
      head "posts/:id", to: "posts#show"
    end

    route = routes.find(
      Zee::Request.new("REQUEST_METHOD" => "HEAD", "PATH_INFO" => "/posts/1")
    )

    refute_nil route
  end

  test "defines route with leading optional segment" do
    routes = Zee::Routes.new do
      get "(/:locale)/posts/:id", to: "posts#show"
    end

    route = routes.find(
      Zee::Request.new("REQUEST_METHOD" => "GET", "PATH_INFO" => "/posts/1")
    )

    refute_nil route

    route = routes.find(
      Zee::Request.new("REQUEST_METHOD" => "GET", "PATH_INFO" => "/en/posts/1")
    )

    refute_nil route
  end

  test "defines route with trailing optional segment" do
    routes = Zee::Routes.new do
      get "archive(/:category)", to: "archive#show"
    end

    route = routes.find(
      Zee::Request.new("REQUEST_METHOD" => "GET", "PATH_INFO" => "/archive")
    )

    refute_nil route

    route = routes.find(
      Zee::Request.new("REQUEST_METHOD" => "GET", "PATH_INFO" => "/archive/all")
    )

    refute_nil route
  end

  test "sets route params" do
    routes = Zee::Routes.new do
      get "posts/:id", to: "posts#show"
    end

    request = Zee::Request.new(
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/posts/1"
    )
    route = routes.find(request)

    refute_nil route
    assert_equal "1", request.params[:id]
  end

  test "sets route params with defaults option" do
    routes = Zee::Routes.new do
      get "(/:locale)/posts/:id", to: "posts#show", defaults: {locale: "en"}
    end

    request = Zee::Request.new(
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/posts/1"
    )
    route = routes.find(request)

    refute_nil route
    assert_equal "1", request.params[:id]
    assert_equal "en", request.params[:locale]
  end

  test "sets route params with defaults" do
    routes = Zee::Routes.new do
      defaults locale: "en" do
        get "(/:locale)/posts/:id", to: "posts#show"
      end
    end

    request = Zee::Request.new(
      "REQUEST_METHOD" => "GET",
      "PATH_INFO" => "/posts/1"
    )
    route = routes.find(request)

    refute_nil route
    assert_equal "1", request.params[:id]
    assert_equal "en", request.params[:locale]
  end
end
