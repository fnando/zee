# frozen_string_literal: true

require "test_helper"

class AppTest < Minitest::Test
  test "generates new app" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {database: "sqlite"}
    generator.destination_root = app
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    assert app.join(".gitignore").file?
    assert app.join(".rubocop.yml").file?
    assert app.join(".ruby-version").file?
    assert app.join(".env.development").file?
    assert app.join(".env.test").file?
    assert app.join("bin/dev").file?
    assert app.join("app/controllers/base.rb").file?
    assert app.join("app/controllers/pages.rb").file?
    assert app.join("app/views/layouts/application.html.erb").file?
    assert app.join("app/views/pages/home.html.erb").file?
    assert app.join("config.ru").file?
    assert app.join("config/app.rb").file?
    assert app.join("config/boot.rb").file?
    assert app.join("config/environment.rb").file?
    assert app.join("config/secrets/development.key").file?
    assert app.join("config/secrets/test.key").file?
    assert app.join("config/puma.rb").file?
    assert app.join("Gemfile").file?
    assert app.join("Procfile.dev").file?
    assert app.join("tmp/.keep").file?
    assert_equal RUBY_VERSION, app.join(".ruby-version").read.chomp
    assert_includes out, "bundle install"
    assert app.join("bin/dev").executable?
    refute app.join("config/secrets/development.key").world_readable?
    refute app.join("config/secrets/test.key").world_readable?
  end

  test "skips bundle install" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {skip_bundle: true, database: "sqlite"}
    generator.destination_root = app
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    refute_includes out, "bundle install"
  end

  test "uses sqlite" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {database: "sqlite"}
    generator.destination_root = app

    Dir.chdir(app) do
      capture { generator.invoke_all }
    end

    assert app.join(".env.development").file?
    assert app.join(".env.test").file?
    assert_includes app.join(".env.development").read,
                    "DATABASE_URL=sqlite://storage/development.db"
    assert_includes app.join(".env.test").read,
                    "DATABASE_URL=sqlite://storage/test.db"
  end

  test "uses postgresql" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {database: "postgresql"}
    generator.destination_root = app

    Dir.chdir(app) do
      capture { generator.invoke_all }
    end

    assert app.join(".env.development").file?
    assert app.join(".env.test").file?
    assert_includes app.join(".env.development").read,
                    "DATABASE_URL=postgres:///tmp_development"
    assert_includes app.join(".env.test").read,
                    "DATABASE_URL=postgres:///tmp_test"
  end

  test "uses mysql" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {database: "mysql"}
    generator.destination_root = app

    Dir.chdir(app) do
      capture { generator.invoke_all }
    end

    assert app.join(".env.development").file?
    assert app.join(".env.test").file?
    assert_includes app.join(".env.development").read,
                    "DATABASE_URL=mysql2:///tmp_development?encoding=utf8mb4"
    assert_includes app.join(".env.test").read,
                    "DATABASE_URL=mysql2:///tmp_test?encoding=utf8mb4"
  end

  test "uses mariadb" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {database: "mariadb"}
    generator.destination_root = app

    Dir.chdir(app) do
      capture { generator.invoke_all }
    end

    assert app.join(".env.development").file?
    assert app.join(".env.test").file?
    assert_includes app.join(".env.development").read,
                    "DATABASE_URL=mysql2:///tmp_development?encoding=utf8mb4"
    assert_includes app.join(".env.test").read,
                    "DATABASE_URL=mysql2:///tmp_test?encoding=utf8mb4"
  end

  test "fails with an unsupported database" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {database: "foo"}
    generator.destination_root = app

    error = assert_raises RuntimeError do
      capture { generator.invoke_all }
    end

    assert_equal "Unsupported database: foo", error.message
  end
end
