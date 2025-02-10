# frozen_string_literal: true

require "test_helper"

class MigrationTest < Minitest::Test
  test "generates new migration" do
    app = Pathname("tmp")
    generator = Zee::Generators::Migration.new
    generator.options = {name: "create_users"}
    generator.destination_root = app
    timestamp = Time.now.to_i

    Time.stubs(:now).returns(Time.at(timestamp))

    out, _ = Dir.chdir(app) do
      capture_io do
        generator.invoke_all
      end
    end

    assert_path_exists app.join("db/migrations/#{timestamp}_create_users.rb")
    assert_includes out, "db/migrations/#{timestamp}_create_users.rb"
  end

  test "generates new migration with normalized name" do
    app = Pathname("tmp")
    generator = Zee::Generators::Migration.new
    generator.options = {name: "create_users"}
    generator.destination_root = app
    timestamp = Time.now.to_i

    Time.stubs(:now).returns(Time.at(timestamp))

    Dir.chdir(app) do
      capture_io do
        generator.invoke_all
      end
    end

    assert_path_exists app.join("db/migrations/#{timestamp}_create_users.rb")
  end
end
