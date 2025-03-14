# frozen_string_literal: true

require "test_helper"

class SecretsTest < Minitest::Test
  let(:root) { "test/fixtures/sample_app/config/secrets" }
  let(:key) { "#{root}/development.key" }
  let(:secrets_file) { "#{root}/development.yml.enc" }

  test "reads secrets from encrypted file" do
    secrets = Zee::Secrets.new(
      keyring: Zee::Keyring.parse(File.read(key)),
      secrets_file:
    )

    assert_equal "some-api-key", secrets[:api_key]
    assert_equal "some-api-key", secrets.api_key
    assert_respond_to secrets, :api_key
  end

  test "overrides to_s" do
    secrets = Zee::Secrets.new(
      keyring: Zee::Keyring.parse(File.read(key)),
      secrets_file:
    )

    assert_equal "#<Zee::Secrets secrets_file=#{secrets_file}>", secrets.to_s
    assert_equal "#<Zee::Secrets secrets_file=#{secrets_file}>", secrets.inspect
  end

  test "implements respond_to?" do
    secrets = Zee::Secrets.new(
      keyring: Zee::Keyring.parse(File.read(key)),
      secrets_file:
    )

    assert_respond_to secrets, :api_key
  end
end
