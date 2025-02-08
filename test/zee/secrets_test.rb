# frozen_string_literal: true

require "test_helper"

class SecretsTest < Minitest::Test
  test "reads secrets from encrypted file" do
    secrets = Zee::Secrets.new(
      key: File.read("test/fixtures/secrets/main.key"),
      credentials_file: "test/fixtures/secrets/secrets.yml.enc"
    )

    assert_equal "some-api-key", secrets[:api_key]
    assert_equal "some-api-key", secrets.api_key
    assert_respond_to secrets, :api_key
  end
end
