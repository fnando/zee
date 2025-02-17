# frozen_string_literal: true

require "test_helper"

class KeyTest < Minitest::Test
  test "prevents key leaking" do
    key = Zee::Keyring::Key.new(
      id: 1,
      key: "uDiMcWVNTuz//naQ88sOcN+E40CyBRGzGTT7OkoBS6M=",
      size: 16
    )

    assert_equal "#<Zee::Keyring::Key id=1>", key.to_s
    assert_equal "#<Zee::Keyring::Key id=1>", key.inspect
  end

  test "accepts keys with valid size (bytes)" do
    key = Zee::Keyring::Key.new(
      id: 1,
      key: SecureRandom.bytes(32),
      size: 16
    )

    assert_instance_of Zee::Keyring::Key, key
  end

  test "accepts keys with valid size (base64-encoded)" do
    key = Zee::Keyring::Key.new(
      id: 1,
      key: Base64.encode64(SecureRandom.bytes(32)),
      size: 16
    )

    assert_instance_of Zee::Keyring::Key, key
  end

  test "accepts keys with valid size (base64-strict-encoded)" do
    key =
      Zee::Keyring::Key.new(
        id: 1,
        key: Base64.strict_encode64(SecureRandom.bytes(32)),
        size: 16
      )

    assert_instance_of Zee::Keyring::Key, key
  end

  test "raises when key has invalid size" do
    error = assert_raises(Zee::Keyring::InvalidSecret) do
      Zee::Keyring::Key.new(
        id: 1,
        key: SecureRandom.bytes(16),
        size: 16
      )
    end

    assert_equal "Secret must be 32 bytes; got 16", error.message
  end

  test "parses key (AES-128-CBC)" do
    signing_key = "A" * 16
    encryption_key = "B" * 16
    key = Zee::Keyring::Key.new(
      id: 1,
      key: signing_key + encryption_key,
      size: 16
    )

    assert_equal encryption_key, key.encryption_key
    assert_equal signing_key, key.signing_key
  end

  test "parses key (AES-192-CBC)" do
    signing_key = "A" * 24
    encryption_key = "B" * 24
    key = Zee::Keyring::Key.new(
      id: 1,
      key: signing_key + encryption_key,
      size: 24
    )

    assert_equal encryption_key, key.encryption_key
    assert_equal signing_key, key.signing_key
  end

  test "parses key (AES-256-CBC)" do
    signing_key = "A" * 32
    encryption_key = "B" * 32
    key = Zee::Keyring::Key.new(
      id: 1,
      key: signing_key + encryption_key,
      size: 32
    )

    assert_equal encryption_key, key.encryption_key
    assert_equal signing_key, key.signing_key
  end
end
