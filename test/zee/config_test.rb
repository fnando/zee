# frozen_string_literal: true

require "test_helper"

class ConfigTest < Minitest::Test
  test "sets default config" do
    config = Zee::Config.new(env: {})

    assert_equal %i[secret], config.session_options.keys
    assert_equal ::JSON, config.json_serializer
    assert_equal %w[erb], config.template_handlers
    assert_equal ["localhost"], config.allowed_hosts
  end

  test "raises exception for missing mandatory var" do
    error = assert_raises(Zee::Config::MissingEnvironmentVariable) do
      Zee::Config.new(env: {}).instance_eval do
        mandatory :foo, string
      end
    end

    assert_equal "FOO is not defined.", error.message
  end

  test "overrides to_s" do
    config = Zee::Config.new(env: {})

    assert_equal "#<Zee::Config>", config.to_s
    assert_equal "#<Zee::Config>", config.inspect
  end

  test "removes the credential method" do
    config = Zee::Config.new(env: {})

    refute_respond_to config, :credential
  end

  test "raises exception when mandatory key is missing" do
    config = Zee::Config.new(env: {})

    assert_raises Zee::Config::MissingEnvironmentVariable do
      config.instance_eval do
        mandatory :database_url, string
      end
    end
  end

  test "raises exception when property doesn't have callable" do
    config = Zee::Config.new(env: {})

    assert_raises Zee::Config::MissingCallable do
      config.instance_eval do
        property :foo
      end
    end
  end

  test "loads silent config even when mandatory vars aren't defined" do
    ENV["ZEE_SILENT_CONFIG"] = "1"

    config = Zee::Config.new(env: {}) do
      mandatory :missing_env_var, string
    end

    assert_instance_of Zee::Config, config
  end
end
