# frozen_string_literal: true

require "test_helper"

class DatabaseTest < Minitest::Test
  setup { FileUtils.mkdir_p("tmp/storage") }
  teardown { ENV.delete("DATABASE_URL") }

  test "fails when unable to find connection string" do
    exit_code = nil
    err = ""

    Dir.chdir("tmp") do
      capture { Zee::CLI.start(%w[generate migration create_users]) }

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
      capture { Zee::CLI.start(%w[generate migration create_users]) }
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

  test "dumps database schema" do
    ENV["DATABASE_URL"] = "sqlite://storage/development.db"
    exit_code = nil

    Dir.chdir("tmp") do
      capture { Zee::CLI.start(%w[generate migration create_users]) }
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

      capture { Zee::CLI.start(%w[db migrate --verbose]) }
      capture { Zee::CLI.start(%w[db schema dump]) } => {exit_code:}
    end

    # TODO: remove this replace when support for ruby3.3 is dropped.
    actual_schema = File.read("tmp/db/schema.rb")
                        .gsub(/:(\w+)=>/, "\\1: ")

    assert_equal 0, exit_code
    assert_path_exists "tmp/db/schema.rb"
    assert_equal File.read("test/fixtures/schema.rb"), actual_schema
  end

  test "loads database schema" do
    ENV["DATABASE_URL"] = "sqlite://storage/development.db"
    exit_code = nil

    Dir.chdir("tmp") do
      capture { Zee::CLI.start(%w[generate migration create_users]) }
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

      capture { Zee::CLI.start(%w[db migrate --verbose]) }
      capture { Zee::CLI.start(%w[db schema dump]) }
      FileUtils.rm("storage/development.db")
      capture { Zee::CLI.start(%w[db schema load]) } => {exit_code:}
    end

    assert_equal 0, exit_code
    assert_path_exists "tmp/db/schema.rb"
    assert_path_exists "tmp/storage/development.db"

    db = Sequel.connect("sqlite://tmp/storage/development.db")
    migration_name = db[:schema_migrations].first[:filename]

    assert_match(/_create_users\.rb$/, migration_name)
  end

  test "undoes schema" do
    ENV["DATABASE_URL"] = "sqlite://storage/development.db"
    exit_code = nil

    Dir.chdir("tmp") do
      capture { Zee::CLI.start(%w[generate migration create_users]) }
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

      capture { Zee::CLI.start(%w[db migrate]) }
      capture { Zee::CLI.start(%w[db undo]) } => {exit_code:}
    end

    db = Sequel.connect("sqlite://tmp/storage/development.db")

    assert_equal 0, exit_code
    assert_empty db[:schema_migrations].all
    refute_includes File.read("tmp/db/schema.rb"), "Sequel.migrate"
  end

  test "redoes schema" do
    ENV["DATABASE_URL"] = "sqlite://storage/development.db"
    exit_code = nil

    Dir.chdir("tmp") do
      capture { Zee::CLI.start(%w[generate migration create_users]) }
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

      capture { Zee::CLI.start(%w[db migrate]) }
      capture { Zee::CLI.start(%w[db redo]) } => {exit_code:}
    end

    db = Sequel.connect("sqlite://tmp/storage/development.db")
    migration_name = db[:schema_migrations].first[:filename]

    assert_equal 0, exit_code
    assert_match(/_create_users\.rb$/, migration_name)
  end

  test "fails when using wrong schema command" do
    exit_code = nil
    err = nil

    capture { Zee::CLI.start(%w[db schema foo]) } => {exit_code:, err:}

    assert_equal 1, exit_code
    assert_includes err, 'Invalid option: "foo"'
  end
end
