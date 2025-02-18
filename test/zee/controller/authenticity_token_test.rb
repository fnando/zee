# frozen_string_literal: true

require "test_helper"

class AuthenticityTokenTest < Minitest::Test
  include Rack::Test::Methods

  def app
    SampleApp
  end

  test "rejects missing token" do
    post "/posts/new", {}

    assert_equal 422, last_response.status
  end

  test "rejects invalid token" do
    post "/posts/new", {Zee::Controller.csrf_param_name => SecureRandom.hex(32)}

    assert_equal 422, last_response.status
  end

  test "accepts valid token" do
    get "/posts/new"
    authenticity_token = last_response.body

    post "/posts/new", {Zee::Controller.csrf_param_name => authenticity_token}

    assert_equal 200, last_response.status
  end

  test "regenerates token" do
    get "/posts/new"
    first_token = last_response.body

    get "/posts/new"
    second_token = last_response.body

    refute_equal second_token, first_token
  end

  test "rejects previously used token" do
    get "/posts/new"
    authenticity_token = last_response.body

    post "/posts/new", {Zee::Controller.csrf_param_name => authenticity_token}
    post "/posts/new", {Zee::Controller.csrf_param_name => authenticity_token}

    assert_equal 422, last_response.status
  end

  test "accepts tokens via header for xhr requests" do
    get "/posts/new"
    authenticity_token = last_response.body

    header "X-CSRF-TOKEN", authenticity_token
    header "X-REQUESTED-WITH", "XMLHttpRequest"
    post "/posts/new", {}

    assert_equal 200, last_response.status
  end

  test "rejects tokens via header for for non-xhr requests" do
    get "/posts/new"
    authenticity_token = last_response.body

    header "X-CSRF-TOKEN", authenticity_token
    post "/posts/new", {}

    assert_equal 422, last_response.status
  end

  test "accepts valid token per form" do
    get "/categories/new"
    authenticity_token = last_response.body

    post "/categories/new",
         {Zee::Controller.csrf_param_name => authenticity_token}

    assert_equal 200, last_response.status
  end

  test "rejects token per form without hmac" do
    get "/categories/new"
    authenticity_token = last_response.body.split("--").last

    post "/posts/new",
         {Zee::Controller.csrf_param_name => authenticity_token}

    assert_equal 422, last_response.status
  end

  test "rejects token per form in a different url" do
    get "/categories/new"
    authenticity_token = last_response.body

    post "/posts/new",
         {Zee::Controller.csrf_param_name => authenticity_token}

    assert_equal 422, last_response.status
  end

  test "rejects token per form in a different request method" do
    get "/categories/new"
    authenticity_token = last_response.body

    patch "/categories/new",
          {Zee::Controller.csrf_param_name => authenticity_token}

    assert_equal 422, last_response.status
  end
end
