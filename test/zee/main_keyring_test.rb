# frozen_string_literal: true

require "test_helper"

class MainKeyringTest < Minitest::Test
  teardown { ENV.delete("ZEE_KEYRING") }

  test "retrieves key from env vars" do
    ENV["ZEE_KEYRING"] = JSON.dump(
      "0" => SecureRandom.hex(32),
      "digest_salt" => SecureRandom.hex(32)
    )

    keyring = Zee::MainKeyring.read(:development)

    assert_instance_of Zee::Keyring, keyring
    assert_equal Zee::Keyring::Encryptor::AES::AES256GCM, keyring.encryptor
  end

  test "retrieves key from file" do
    contents = File.read(
      "./test/fixtures/sample_app/config/secrets/development.key"
    )

    File.expects(:read).returns(contents)

    keyring = Dir.chdir("test/fixtures/sample_app") do
      Zee::MainKeyring.read(:development)
    end

    assert_instance_of Zee::Keyring, keyring
  end

  test "fails when key is missing" do
    error = assert_raises(Zee::MainKeyring::MissingKeyError) do
      Zee::MainKeyring.read(:production)
    end

    assert_equal(
      "Set ZEE_KEYRING or create config/secrets/production.key",
      error.message
    )
  end
end
