# frozen_string_literal: true

require "test_helper"

class MigrationTest < Minitest::Test
  let(:app) { Pathname("tmp") }
  let(:migrations) { app.join("db/migrations") }
  let(:timestamp) { Time.new(2025, 2, 12).to_i }

  setup do
    Time.stubs(:now).returns(Time.at(timestamp))
  end

  def new_generator(name, fields = [])
    generator = Zee::Generators::Migration.new
    generator.options = {name:, fields:}
    generator.destination_root = app
    generator
  end

  test "generates new migration" do
    generator = new_generator("some_migration")
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    assert_path_exists app.join("db/migrations/#{timestamp}_some_migration.rb")
    assert_includes out, "db/migrations/#{timestamp}_some_migration.rb"
  end

  test "generates migration to create new table" do
    generated_file = app.join("db/migrations/#{timestamp}_create_users.rb")
    generator = new_generator("create_users")
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    assert_path_exists generated_file
    assert_includes out, "db/migrations/#{timestamp}_create_users.rb"
    assert_includes generated_file.read, "create_table :users"
  end

  test "generates migration to create new table with columns" do
    generated_file = app.join("db/migrations/#{timestamp}_create_users.rb")
    generator = new_generator(
      "create_users",
      ["name:string", "email:string:null(false):index(unique)"]
    )
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    contents = generated_file.read

    assert_path_exists generated_file
    assert_includes out, "db/migrations/#{timestamp}_create_users.rb"
    assert_includes contents, "create_table :users"
    assert_includes contents, "String :name\n"
    assert_includes contents,
                    "String :email, null: false, index: {unique: true}\n"
  end

  test "generates migration to drop table" do
    generated_file = app.join("db/migrations/#{timestamp}_remove_users.rb")
    generator = new_generator("remove_users")
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    contents = generated_file.read

    assert_path_exists generated_file
    assert_includes out, "db/migrations/#{timestamp}_remove_users.rb"
    assert_includes contents, "drop_table :users"
  end

  test "generates migration to drop multiple tables" do
    generated_file =
      app.join("db/migrations/#{timestamp}_remove_users_and_posts.rb")
    generator = new_generator("remove_users_and_posts")
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    contents = generated_file.read

    assert_path_exists generated_file
    assert_includes out, "db/migrations/#{timestamp}_remove_users_and_posts.rb"
    assert_includes contents, "drop_table :users"
    assert_includes contents, "drop_table :posts"
  end

  test "generates migration to drop column" do
    generated_file = migrations.join("#{timestamp}_remove_email_from_users.rb")
    generator = new_generator("remove_email_from_users")
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    contents = generated_file.read

    assert_path_exists generated_file
    assert_includes out,
                    "db/migrations/#{timestamp}_remove_email_from_users.rb"
    assert_includes contents, "alter_table :users"
    assert_includes contents, "drop_column :email"
  end

  test "generates migration to drop multiple columns" do
    generated_file =
      migrations.join("#{timestamp}_remove_email_and_bio_from_users.rb")
    generator = new_generator("remove_email_and_bio_from_users")
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    contents = generated_file.read

    assert_path_exists generated_file
    assert_includes(
      out,
      "db/migrations/#{timestamp}_remove_email_and_bio_from_users.rb"
    )
    assert_includes contents, "alter_table :users"
    assert_includes contents, "drop_column :email"
    assert_includes contents, "drop_column :bio"
  end

  test "generates migration to add column to existing table" do
    generated_file =
      migrations.join("#{timestamp}_add_email_to_users.rb")
    generator = new_generator("add_email_to_users")
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    contents = generated_file.read

    assert_path_exists generated_file
    assert_includes(
      out,
      "db/migrations/#{timestamp}_add_email_to_users.rb"
    )
    assert_includes contents, "alter_table :users"
    assert_includes contents, "add_column :email, String"
  end

  test "generates migration to add multiple columns to existing table" do
    generated_file =
      migrations.join("#{timestamp}_add_email_and_bio_to_users.rb")
    generator = new_generator("add_email_and_bio_to_users")
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    contents = generated_file.read

    assert_path_exists generated_file
    assert_includes(
      out,
      "db/migrations/#{timestamp}_add_email_and_bio_to_users.rb"
    )
    assert_includes contents, "alter_table :users"
    assert_includes contents, "add_column :email, String\n"
    assert_includes contents, "add_column :bio, String\n"
  end

  test "generates migration to add column with options to existing table" do
    generated_file =
      migrations.join("#{timestamp}_add_email_to_users.rb")
    generator = new_generator(
      "add_email_to_users",
      ["email:string:null(false)"]
    )
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    contents = generated_file.read

    assert_path_exists generated_file
    assert_includes(
      out,
      "db/migrations/#{timestamp}_add_email_to_users.rb"
    )
    assert_includes contents, "alter_table :users"
    assert_includes contents, "add_column :email, String, null: false\n"
  end

  test "generates migration to add index to existing table" do
    generated_file =
      migrations.join("#{timestamp}_add_index_to_email_on_users.rb")
    generator = new_generator("add_index_to_email_on_users")
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    contents = generated_file.read

    assert_path_exists generated_file
    assert_includes(
      out,
      "db/migrations/#{timestamp}_add_index_to_email_on_users.rb"
    )
    assert_includes contents, "alter_table :users"
    assert_includes contents, "add_index :email\n"
  end

  test "generates migration to add multiple columns index to existing table" do
    generated_file =
      migrations.join("#{timestamp}_add_index_to_email_and_status_on_users.rb")
    generator = new_generator("add_index_to_email_and_status_on_users")
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    contents = generated_file.read

    assert_path_exists generated_file
    assert_includes(
      out,
      "db/migrations/#{timestamp}_add_index_to_email_and_status_on_users.rb"
    )
    assert_includes contents, "alter_table :users"
    assert_includes contents, "add_index %i[email status]\n"
  end

  test "generates migration to remove index from existing table" do
    generated_file =
      migrations.join("#{timestamp}_remove_index_from_email_on_users.rb")
    generator = new_generator("remove_index_from_email_on_users")
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    contents = generated_file.read

    assert_path_exists generated_file
    assert_includes(
      out,
      "db/migrations/#{timestamp}_remove_index_from_email_on_users.rb"
    )
    assert_includes contents, "alter_table :users"
    assert_includes contents, "drop_index :email\n"
  end

  test "generates migration to remove multi-column index from existing table" do
    generated_file =
      migrations
      .join("#{timestamp}_remove_index_from_email_and_status_on_users.rb")
    generator = new_generator("remove_index_from_email_and_status_on_users")
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    contents = generated_file.read

    assert_path_exists generated_file
    assert_includes(
      out,
      "db/migrations/#{timestamp}_remove_index_from_email_and_status_on_users" \
      ".rb"
    )
    assert_includes contents, "alter_table :users"
    assert_includes contents, "drop_index %i[email status]\n"
  end
end
