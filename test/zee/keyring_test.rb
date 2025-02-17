# frozen_string_literal: true

require "test_helper"

class KeyringTest < Minitest::Test
  test "clears keyring" do
    keys = {
      "0" => "0dab9f80f8e1ebad17a080ee6b7616d773ea3f95bef9a88784c01c1ed4e28520"
    }
    keyring = Zee::Keyring.new(keys, digest_salt: "")

    assert_equal 1, keyring.size

    keyring.clear

    assert_equal 0, keyring.size
  end

  test "raises error for missing key" do
    keys = {
      "0" => "ab961301a07070546ff9d65964dbec1b2534ccf3bb6879a17a59b72f8f395138"
    }
    keyring = Zee::Keyring.new(keys, digest_salt: "")

    error = assert_raises(Zee::Keyring::UnknownKey) do
      keyring[1]
    end

    assert_equal "key=1 is not available on keyring", error.message
  end

  test "returns digest when encrypting" do
    keys = {
      "0" => "cb1bdd060a21689516187c07362208bea7b207f14c35cfe9e69edf70f87312af"
    }
    keyring = Zee::Keyring.new(keys, digest_salt: "")

    *, digest = keyring.encrypt("42")

    assert_equal "92cfceb39d57d914ed8b14d0e37643de0797ae56", digest

    keyring[1] =
      "a7393be92847b6044611357244f0ac37dd1591ae0b729ca032ad99551911e4cc"
    *, digest = keyring.encrypt("37")

    assert_equal "cb7a1d775e800fd1ee4049f7dca9e041eb9ba083", digest
  end

  test "returns digest with custom salt" do
    digest_salt = "a"
    keys = {
      "0" => "89709769c71a6188c49952c183b58580582dd3ce6c50da167f70e68c18655798"
    }
    keyring = Zee::Keyring.new(keys, digest_salt: digest_salt)

    *, digest = keyring.encrypt("42")

    assert_equal "118c884d37dde5fb6816daba052d94e82f1dc41f", digest

    keyring[1] =
      "8bec0727542914c98dc02be89ab5ef0b8890e569c0d51d1873ab6c75d7295bc6"
    *, digest = keyring.encrypt("37")

    assert_equal "339306c56026a22fdd522116973cde9a8205370e", digest
  end

  test "fails with missing digest salt" do
    error = assert_raises(Zee::Keyring::MissingDigestSalt) do
      Zee::Keyring.new({})
    end

    assert_includes error.message, "Please provide :digest_salt"

    Zee::Keyring.new({}, digest_salt: "")
  end

  test "returns keyring id when encrypting" do
    keys = {
      "0" => "d9c55e2bc32d204173a24152b14d9419ea41ba23a5ddc1f6a1e02531b6587488"
    }
    keyring = Zee::Keyring.new(keys, digest_salt: "")

    _, keyring_id, _ = keyring.encrypt("42")

    assert_equal 0, keyring_id

    keyring[1] =
      "aa1d99f7a3a9acb73a2ad5f4a8e12efd26d64de04b1ebd1053f9f64b45fa5363"
    _, keyring_id, _ = keyring.encrypt("42")

    assert_equal 1, keyring_id
  end

  test "rotates key" do
    # First encrypt and decrypt value using initial key.
    keys = {
      "0" => "8ffd106a3d419691263458c7f94625a6721c5dfbfa8700bedef91390b0a7429e"
    }
    keyring = Zee::Keyring.new(keys, digest_salt: "")
    encrypted, keyring_id, _ = keyring.encrypt("42")
    decrypted = keyring.decrypt(encrypted, keyring_id)

    assert_equal 0, keyring_id
    assert_equal "42", decrypted

    # Then add a new key and encrypt and decrypt value using new key.
    keys = keys.merge(
      "1" => "4b820e099820cfc7f508dd94ea54c60ed22586d46e448ac6ca414eeb90ace4c9"
    )
    keyring = Zee::Keyring.new(keys, digest_salt: "")
    encrypted, keyring_id, _ = keyring.encrypt(decrypted)
    decrypted = keyring.decrypt(encrypted, keyring_id)

    assert_equal 1, keyring_id
    assert_equal "42", decrypted

    # Finally, remove key=0 and encrypt and decrypt value.
    keys.delete("0")
    keyring = Zee::Keyring.new(keys, digest_salt: "")
    encrypted, keyring_id, _ = keyring.encrypt(decrypted)
    decrypted = keyring.decrypt(encrypted, keyring_id)

    assert_equal 1, keyring_id
    assert_equal "42", decrypted
  end

  test "raises when hmac doesn't match" do
    keyring = Zee::Keyring.new(
      {"0" => "uDiMcWVNTuz//naQ88sOcN+E40CyBRGzGTT7OkoBS6M="},
      encryptor: Zee::Keyring::Encryptor::AES::AES128CBC,
      digest_salt: ""
    )

    another_keyring = Zee::Keyring.new(
      {"0" => "60ds/tHrkZTWjFiy89z5vgKuKId0axhndfSjAKmBg+8="},
      encryptor: Zee::Keyring::Encryptor::AES::AES128CBC,
      digest_salt: ""
    )

    encrypted, keyring_id, _ = keyring.encrypt("42")

    error = assert_raises(Zee::Keyring::InvalidAuthentication) do
      another_keyring.decrypt(encrypted, keyring_id)
    end

    assert_match(/Expected HMAC to be .*?; got .*? instead/, error.message)
  end

  test "encrypts using AES-128-CBC" do
    keys = {"0" => "uDiMcWVNTuz//naQ88sOcN+E40CyBRGzGTT7OkoBS6M="}
    keyring = Zee::Keyring.new(
      keys,
      encryptor: Zee::Keyring::Encryptor::AES::AES128CBC,
      digest_salt: ""
    )

    encrypted, keyring_id, _ = keyring.encrypt("42")
    decrypted = keyring.decrypt(encrypted, keyring_id)

    assert_equal "42", decrypted
  end

  test "encrypts using AES-192-CBC" do
    keys = {
      "0" => "wtnnoK+5an+FPtxnkdUDrNw6fAq8yMkvCvzWpriLL9TQTR2WC/k+XPahYFPvCemG"
    }
    keyring = Zee::Keyring.new(
      keys,
      encryptor: Zee::Keyring::Encryptor::AES::AES192CBC,
      digest_salt: ""
    )

    encrypted, keyring_id, _ = keyring.encrypt("42")
    decrypted = keyring.decrypt(encrypted, keyring_id)

    assert_equal "42", decrypted
  end

  test "encrypts using AES-256-CBC" do
    keys = {
      "0" => "XZXC+c7VUVGpyAceSUCOBbrp2fjJeeHwoaMQefgSCfp0/HABY5yJ7zRiLZb" \
             "DlDZ7HytCRsvP4CxXt5hUqtx9Uw=="
    }
    keyring = Zee::Keyring.new(
      keys,
      encryptor: Zee::Keyring::Encryptor::AES::AES256CBC,
      digest_salt: ""
    )

    encrypted, keyring_id, _ = keyring.encrypt("42")
    decrypted = keyring.decrypt(encrypted, keyring_id)

    assert_equal "42", decrypted
  end

  test "encrypts using AES-256-GCM" do
    keys = {
      "0" => "XZXC+c7VUVGpyAceSUCOBbrp2fjJeeHwoaMQefgSCfp0/HABY5yJ7zRiLZb" \
             "DlDZ7HytCRsvP4CxXt5hUqtx9Uw=="
    }
    keyring = Zee::Keyring.new(
      keys,
      encryptor: Zee::Keyring::Encryptor::AES::AES256GCM,
      digest_salt: ""
    )

    encrypted, keyring_id, _ = keyring.encrypt("42")
    decrypted = keyring.decrypt(encrypted, keyring_id)

    assert_equal "42", decrypted
  end

  test "works with keys as symbols" do
    sym_key = :"0"
    key = "10c49ac6387872559209e4971c12662835ad42783d1439419a4f9ad90b481218"
    keys = {sym_key => key}
    keyring = Zee::Keyring.new(keys, digest_salt: "")

    *, digest = keyring.encrypt("42")

    assert_equal "92cfceb39d57d914ed8b14d0e37643de0797ae56", digest
  end
end
