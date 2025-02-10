# frozen_string_literal: true

require "test_helper"

class SecretsTest < Minitest::Test
  setup { FileUtils.mkdir_p "tmp/config/secrets" }

  test "generates a key" do
    Dir.chdir("tmp") do
      capture do
        Zee::CLI::Secrets.start(["create", "-e", "development"])
      end
    end

    assert_path_exists "tmp/config/secrets/development.key"
    refute File.world_readable?("tmp/config/secrets/development.key")
    assert_path_exists "tmp/config/secrets/development.yml.enc"
  end

  test "fails to generate key when it already exists" do
    FileUtils.touch("tmp/config/secrets/development.key")
    File.chmod(600, "tmp/config/secrets/development.key")
    exit_code = nil
    err = nil

    Dir.chdir("tmp") do
      capture do
        Zee::CLI::Secrets.start(["create", "-e", "development"])
      end => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err, "config/secrets/development.key already exists"
  end

  test "fails to generate key when encrypted file already exists" do
    FileUtils.touch("tmp/config/secrets/development.yml.enc")
    exit_code = nil
    err = nil

    Dir.chdir("tmp") do
      capture do
        Zee::CLI::Secrets.start(["create", "-e", "development"])
      end => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err,
                    "config/secrets/development.yml.enc already exists"
  end
end
