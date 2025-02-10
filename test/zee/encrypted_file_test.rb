require "test_helper"

class EncryptedFileTest < Minitest::Test
  setup do
    FileUtils.rm_rf "tmp/file.txt"
  end

  test "overrides to_s" do
    file = Zee::EncryptedFile.new(
      path: "tmp/file.txt",
      key: SecureRandom.random_bytes(32)
    )

    assert_equal "#<Zee::EncryptedFile path=tmp/file.txt>", file.to_s
  end

  test "encrypts and decrypts a file" do
    file = Zee::EncryptedFile.new(
      path: "tmp/file.txt",
      key: SecureRandom.random_bytes(32)
    )

    refute_path_exists "tmp/file.txt"

    file.write "encrypted"

    assert_path_exists "tmp/file.txt"

    refute_equal "encrypted", File.read("tmp/file.txt")
    assert_equal "encrypted", file.read
  end
end
