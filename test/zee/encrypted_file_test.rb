# frozen_string_literal: true

require "test_helper"

class EncryptedFileTest < Minitest::Test
  setup do
    FileUtils.rm_rf "tmp/file.txt"
  end

  let(:keyring) do
    Zee::Keyring.new(
      {"0" => SecureRandom.hex(32)},
      digest_salt: SecureRandom.hex(32)
    )
  end

  test "overrides to_s" do
    file = Zee::EncryptedFile.new(path: "tmp/file.txt", keyring:)

    assert_equal "#<Zee::EncryptedFile path=tmp/file.txt>", file.to_s
    assert_equal "#<Zee::EncryptedFile path=tmp/file.txt>", file.inspect
  end

  test "encrypts and decrypts a file" do
    file = Zee::EncryptedFile.new(path: "tmp/file.txt", keyring:)

    refute_path_exists "tmp/file.txt"

    file.write "encrypted"

    assert_path_exists "tmp/file.txt"

    refute_equal "encrypted", File.read("tmp/file.txt")
    assert_equal "encrypted", file.read
  end
end
