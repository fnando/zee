# frozen_string_literal: true

require "test_helper"

class EncryptedAttributesTest < Minitest::Test
  DEFAULT_KEYRING = {"0" => SecureRandom.bytes(64)}.freeze

  def create_model(&)
    db = Sequel.connect("sqlite::memory:")
    db.execute <<~SQL
      CREATE TABLE users (
        id integer primary key not null,
        keyring_id integer,
        encrypted_secret text,
        secret_digest text,
        encrypted_other_secret text
      )
    SQL

    Class.new(Sequel::Model(db[:users])) do
      plugin :encrypted_attributes
      self.strict_param_setting = false
      instance_eval(&) if block_given?
    end
  end

  test "works with inheritance" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    model = Class.new(model)

    user = model.create(secret: "42")
    user.reload

    assert_equal "42", user.secret
    refute_nil user.encrypted_secret
    refute_equal user.encrypted_secret, user.secret
  end

  test "ignores classes that did not setup the keyring with keyring" do
    model = create_model
    user = model.create

    refute user.new?
  end

  test "raises exception when default keyring is used" do
    model = create_model do
      encrypt :secret
    end

    assert_raises(Zee::Keyring::EmptyKeyring) do
      model.create(secret: "42")
    end
  end

  test "encrypts value" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")
    user.reload

    assert_equal "42", user.secret
    refute_nil user.encrypted_secret
    refute_equal user.encrypted_secret, user.secret
  end

  test "saves keyring id" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")
    user.reload

    assert_equal 0, user.keyring_id
  end

  test "handles nil values during encryption" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret, :other_secret
    end

    user = model.create(secret: "42", other_secret: nil)
    user.reload

    assert_equal "42", user.secret
    assert_nil user.other_secret
  end

  test "saves digest value" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: "a"
      encrypt :secret
    end

    user = model.create(secret: "42")

    assert_equal "118c884d37dde5fb6816daba052d94e82f1dc41f", user.secret_digest
  end

  test "finds record via digest value" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: "a"
      encrypt :secret
    end

    user = model.create(secret: "42")

    assert_equal user,
                 model.first(secret_digest: model.keyring.digest("42"))
  end

  test "updates encrypted value" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")
    user.secret = "new secret"
    user.save

    user.reload

    assert_equal "new secret", user.secret
    refute_nil user.encrypted_secret
    refute_equal user.encrypted_secret, user.secret
    assert_equal 0, user.keyring_id
  end

  test "updates encrypted value using set" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")
    user.set(secret: "new secret")
    user.save

    user.reload

    assert_equal "new secret", user.secret
    refute_nil user.encrypted_secret
    refute_equal user.encrypted_secret, user.secret
    assert_equal 0, user.keyring_id
  end

  test "updates digest" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")

    assert_equal "92cfceb39d57d914ed8b14d0e37643de0797ae56", user.secret_digest

    user.secret = "37"
    user.save
    user.reload

    assert_equal "cb7a1d775e800fd1ee4049f7dca9e041eb9ba083", user.secret_digest
  end

  test "assigns digest even without saving" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.new(secret: "42")

    assert_equal "92cfceb39d57d914ed8b14d0e37643de0797ae56", user.secret_digest
  end

  test "assigns nil values" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.new(secret: nil)

    assert_nil user.secret
    assert_nil user.encrypted_secret
    assert_nil user.secret_digest
  end

  test "assigns non-string values" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: 1234)
    user.reload

    assert_equal "1234", user.secret
  end

  test "assigns nil after saving encrypted value" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")
    user.reload

    assert_equal "42", user.secret

    user.secret = nil

    assert_nil user.secret
    assert_nil user.encrypted_secret
    assert_nil user.secret_digest
  end

  test "encrypts with newer key when assigning new value" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")

    model.keyring["1"] = SecureRandom.bytes(64)

    user.update(secret: "new secret")
    user.reload

    assert_equal "new secret", user.secret
    refute_nil user.encrypted_secret
    refute_equal user.encrypted_secret, user.secret
    assert_equal 1, user.keyring_id
  end

  test "encrypts with newer key when saving" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")

    model.keyring["1"] = SecureRandom.bytes(64)

    user.save
    user.reload

    assert_equal "42", user.secret
    refute_nil user.encrypted_secret
    refute_equal user.encrypted_secret, user.secret
    assert_equal 1, user.keyring_id
  end

  test "encrypts several columns at once" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret, :other_secret
    end

    user = model.create(secret: "42", other_secret: "other secret")
    user.reload

    assert_equal "42", user.secret
    assert_equal "other secret", user.other_secret
    refute_nil user.encrypted_secret
    refute_nil user.encrypted_other_secret
    refute_equal user.encrypted_secret, user.secret
    refute_equal user.encrypted_other_secret, user.other_secret
    assert_equal 0, user.keyring_id
  end

  test "encrypts columns with different keys set at different times" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret, :other_secret
    end

    user = model.create(secret: "42", other_secret: "other secret")
    user.reload

    assert_equal "42", user.secret
    assert_equal "other secret", user.other_secret
    assert_equal 0, user.keyring_id

    model.keyring["1"] = SecureRandom.bytes(64)

    user.secret = "new secret"
    user.save
    user.reload

    assert_equal "new secret", user.secret
    assert_equal "other secret", user.other_secret
    assert_equal 1, user.keyring_id
  end

  test "encrypts column with most recent key" do
    model = create_model do
      keyring Hash("0" => SecureRandom.bytes(64),
                   "1" => SecureRandom.bytes(64)),
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")
    user.reload

    assert_equal "42", user.secret
    assert_equal 1, user.keyring_id
  end

  test "raises exception when key is missing" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    model.create(secret: "42")

    model.keyring.clear
    model.keyring["1"] = SecureRandom.bytes(64)

    assert_raises(Zee::Keyring::UnknownKey) { model.first.secret }
  end

  test "caches decrypted value" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    model.keyring.expects(:decrypt).once
    user = model.create(secret: "42")

    2.times { user.secret }
  end

  test "clears cache when assigning values" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    model.keyring.expects(:decrypt).twice.returns("DECRYPTED")

    user = model.create(secret: "42")
    user.secret
    user.secret = "37"
    user.secret
  end

  test "rotates key" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")
    user.reload

    assert_equal "42", user.secret
    assert_equal 0, user.keyring_id

    model.keyring["1"] = SecureRandom.bytes(64)

    user.keyring_rotate!
    user.reload

    assert_equal "42", user.secret
    assert_equal 1, user.keyring_id
  end

  test "encrypts all attributes when setting only one attribute" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret, :other_secret
    end

    model.create(secret: "42", other_secret: "37")
    user = model.first

    assert_equal "42", user.secret
    assert_equal 0, user.keyring_id

    model.keyring["1"] = SecureRandom.bytes(64)

    user.secret = "24"
    user.save

    user.reload

    assert_equal "24", user.secret
    assert_equal "37", user.other_secret
    assert_equal 1, user.keyring_id
  end

  test "returns unitialized attributes" do
    model = create_model do
      keyring DEFAULT_KEYRING,
              digest_salt: ""
      encrypt :secret
    end

    user = model.new

    assert_nil user.secret
  end

  test "encrypts using AES-128-CBC" do
    model = create_model do
      keyring_store = {"0" => "uDiMcWVNTuz//naQ88sOcN+E40CyBRGzGTT7OkoBS6M="}
      keyring keyring_store,
              encryptor: Zee::Keyring::Encryptor::AES::AES128CBC,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")
    user.reload

    assert_equal "42", user.secret
    assert_equal 0, user.keyring_id
  end

  test "encrypts using AES-192-CBC" do
    model = create_model do
      keyring_store = {
        "0" => "wtnnoK+5an+FPtxnkdUDrNw6fAq8yMkvCvzWpriLL9TQTR2WC" \
               "/k+XPahYFPvCemG"
      }
      keyring keyring_store,
              encryptor: Zee::Keyring::Encryptor::AES::AES192CBC,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")
    user.reload

    assert_equal "42", user.secret
    assert_equal 0, user.keyring_id
  end

  test "encrypts using AES-256-CBC" do
    model = create_model do
      keyring_store = {
        "0" => "XZXC+c7VUVGpyAceSUCOBbrp2fjJeeHwoaMQefgSCfp0" \
               "/HABY5yJ7zRiLZbDlDZ7HytCRsvP4CxXt5hUqtx9Uw=="
      }
      keyring keyring_store,
              encryptor: Zee::Keyring::Encryptor::AES::AES256CBC,
              digest_salt: ""
      encrypt :secret
    end

    user = model.create(secret: "42")
    user.reload

    assert_equal "42", user.secret
    assert_equal 0, user.keyring_id
  end

  test "wraps json attributes" do
    model = create_model do
      keyring DEFAULT_KEYRING, digest_salt: ""
      encrypt :secret, encoder: JSON
    end

    user = model.create(secret: {message: "hello"})
    user.reload

    assert_equal Hash("message" => "hello"), user.secret
  end

  test "wraps json with symbolized attributes" do
    model = create_model do
      keyring DEFAULT_KEYRING, digest_salt: ""
      encrypt :secret, encoder: Zee::Encoders::JSONEncoder
    end

    user = model.create(secret: {message: "hello"})
    user.reload

    assert_equal Hash(message: "hello"), user.secret
  end

  test "returns default value (callable)" do
    model = create_model do
      keyring DEFAULT_KEYRING, digest_salt: ""
      encrypt :secret,
              encoder: Zee::Encoders::JSONEncoder,
              default: ->(_) { {} }
    end

    user = model.new

    assert_empty(user.secret)
  end

  test "returns default value" do
    model = create_model do
      keyring DEFAULT_KEYRING, digest_salt: ""
      encrypt :secret,
              encoder: Zee::Encoders::JSONEncoder,
              default: "sekret"
    end

    user = model.new

    assert_equal "sekret", user.secret
  end
end
