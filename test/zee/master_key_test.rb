# frozen_string_literal: true

require "test_helper"

class MasterKeyTest < Minitest::Test
  teardown { ENV.delete("ZEE_MASTER_KEY") }

  test "retrieves key from env vars" do
    key = SecureRandom.hex(16)
    ENV["ZEE_MASTER_KEY"] = key

    assert_equal key, Zee::MasterKey.read(:development)
  end

  test "retrieves key from file" do
    key =
      File.read("./test/fixtures/master_key/config/secrets/development.key")
          .chomp

    found_key = Dir.chdir("test/fixtures/master_key") do
      Zee::MasterKey.read(:development)
    end

    assert_equal key, found_key
  end

  test "fails when key is missing" do
    error = assert_raises(Zee::MasterKey::MissingKeyError) do
      Dir.chdir("test/fixtures/master_key") do
        Zee::MasterKey.read(:production)
      end
    end

    assert_equal(
      "Set ZEE_MASTER_KEY or create config/secrets/production.key",
      error.message
    )
  end
end
