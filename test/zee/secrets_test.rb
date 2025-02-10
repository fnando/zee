require "test_helper"

class SecretsTest < Minitest::Test
  test "reads secrets from encrypted file" do
    secrets = Zee::Secrets.new(
      key: File.read("test/fixtures/secrets/main.key"),
      secrets_file: "test/fixtures/secrets/secrets.yml.enc"
    )

    assert_equal "some-api-key", secrets[:api_key]
    assert_equal "some-api-key", secrets.api_key
    assert_respond_to secrets, :api_key
  end

  test "overrides to_s" do
    secrets = Zee::Secrets.new(
      key: File.read("test/fixtures/secrets/main.key"),
      secrets_file: "test/fixtures/secrets/secrets.yml.enc"
    )

    assert_equal(
      "#<Zee::Secrets secrets_file=test/fixtures/secrets/secrets.yml.enc>",
      secrets.to_s
    )
  end
end
