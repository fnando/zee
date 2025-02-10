# frozen_string_literal: true

require "test_helper"

class DatabaseTest < Minitest::Test
  setup { FileUtils.mkdir_p("tmp/storage") }
  teardown { ENV.delete("DATABASE_URL") }

  test "fails when unable to find connection string" do
    exit_code = nil
    err = ""

    Dir.chdir("tmp") do
      capture do
        Zee::CLI.start([
          "generate",
          "migration",
          "--name", "create_users"
        ])
      end

      migration_file = Pathname(Dir["db/migrations/*.rb"].first)

      migration_file.write <<~RUBY
        Sequel.migration do
          change do
            create_table(:users) do
              primary_key :id
            end
          end
        end
      RUBY

      capture { Zee::CLI.start(%w[db migrate --verbose]) } => {exit_code:, err:}

      assert_equal 1, exit_code
      assert_includes err, "ERROR: No connection string found"
      refute_path_exists "tmp/storage/development.db"
    end
  end

  test "applies migration file" do
    ENV["DATABASE_URL"] = "sqlite://storage/development.db"
    exit_code = nil
    out = ""

    Dir.chdir("tmp") do
      capture do
        Zee::CLI.start(["generate", "migration", "--name", "create_users"])
      end
    end

    Dir.chdir("tmp") do
      migration_file = Pathname(Dir["db/migrations/*.rb"].first)

      migration_file.write <<~RUBY
        Sequel.migration do
          change do
            create_table(:users) do
              primary_key :id
            end
          end
        end
      RUBY

      capture { Zee::CLI.start(%w[db migrate --verbose]) } => {out:, exit_code:}
    end

    refute_equal 1, exit_code
    assert_path_exists "tmp/storage/development.db"
    assert_includes out, "CREATE TABLE `users`"
  end
end
