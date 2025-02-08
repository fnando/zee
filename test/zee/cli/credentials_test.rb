# frozen_string_literal: true

require "test_helper"

class CredentialsTest < Minitest::Test
  setup { FileUtils.rm_rf "tmp" }
  setup { FileUtils.mkdir_p "tmp/config/credentials" }

  test "generates a key" do
    Dir.chdir("tmp") do
      capture_io do
        Zee::CLI::Credentials.start(["create", "-e", "development"])
      end
    end

    assert_path_exists "tmp/config/credentials/development.key"
    refute File.world_readable?("tmp/config/credentials/development.key")
    assert_path_exists "tmp/config/credentials/development.yml.enc"
  end

  test "fails to generate key when it already exists" do
    FileUtils.touch("tmp/config/credentials/development.key")
    File.chmod(600, "tmp/config/credentials/development.key")
    sys_exit = nil

    _, stderr = capture_io do
      sys_exit = Dir.chdir("tmp") do
        capture_exit do
          Zee::CLI::Credentials.start(["create", "-e", "development"])
        end
      end
    end

    refute sys_exit.success?
    assert_includes stderr, "config/credentials/development.key already exists"
  end

  test "fails to generate key when encrypted file already exists" do
    FileUtils.touch("tmp/config/credentials/development.yml.enc")
    sys_exit = nil

    _, stderr = capture_io do
      sys_exit = Dir.chdir("tmp") do
        capture_exit do
          Zee::CLI::Credentials.start(["create", "-e", "development"])
        end
      end
    end

    refute sys_exit.success?
    assert_includes stderr,
                    "config/credentials/development.yml.enc already exists"
  end

  def capture_exit
    yield
  rescue SystemExit => error
    error
  end
end
