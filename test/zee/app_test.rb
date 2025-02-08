# frozen_string_literal: true

require "test_helper"

class AppTest < Minitest::Test
  setup do
    Zee::ENV_NAMES.each {|name| ENV.delete(name) }
  end

  test "uses ZEE_ENV as the env value" do
    ENV["ZEE_ENV"] = "production"

    assert Zee::App.new.env.production?
  end

  test "uses APP_ENV as the env value" do
    ENV["APP_ENV"] = "production"

    assert Zee::App.new.env.production?
  end

  test "uses RACK_ENV as the env value" do
    ENV["RACK_ENV"] = "production"

    assert Zee::App.new.env.production?
  end
end
