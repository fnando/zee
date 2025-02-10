require "test_helper"

class ConfigTest < Minitest::Test
  test "overrides to_s" do
    config = Zee::Config.new(env: {})

    assert_equal "#<Zee::Config>", config.to_s
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
end
