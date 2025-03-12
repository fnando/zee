# frozen_string_literal: true

require "test_helper"

class AppTest < Minitest::Test
  test "generates new app" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {
      database: "sqlite",
      js: "typescript",
      css: "tailwind",
      test: "minitest",
      skip_bundle: true,
      skip_npm: true
    }
    generator.destination_root = app

    Dir.chdir(app) { capture { generator.invoke_all } }

    assert app.join(".gitignore").file?
    assert app.join(".rubocop.yml").file?
    assert app.join(".ruby-version").file?
    assert app.join(".env.development").file?
    assert app.join(".env.test").file?
    assert app.join("bin/dev").file?
    assert app.join("bin/zee").file?
    assert app.join("bin/scripts").file?
    assert app.join("bin/styles").file?
    assert app.join("package.json").file?
    assert app.join("app/controllers/base.rb").file?
    assert app.join("app/assets/styles/app.css").file?
    assert app.join("app/assets/styles/lib/reset.css").file?
    assert app.join("app/assets/styles/lib/colors.css").file?
    assert app.join("app/assets/scripts/app.ts").file?
    assert app.join("app/assets/styles/app.css").file?
    assert app.join("app/controllers/pages.rb").file?
    assert app.join("app/views/layouts/application.html.erb").file?
    assert app.join("app/helpers/app.rb").file?
    assert app.join("app/views/pages/home.html.erb").file?
    assert app.join("config.ru").file?
    assert app.join("config/app.rb").file?
    assert app.join("config/boot.rb").file?
    assert app.join("config/config.rb").file?
    assert app.join("config/initializers/middleware.rb").file?
    assert app.join("config/initializers/sequel.rb").file?
    assert app.join("config/environment.rb").file?
    assert app.join("config/secrets/development.key").file?
    assert app.join("config/secrets/test.key").file?
    assert app.join("config/puma.rb").file?
    assert app.join("Gemfile").file?
    assert app.join("Procfile.dev").file?
    assert app.join("tmp/.keep").file?
    assert app.join("log/.keep").file?
    assert app.join("test/test_helper.rb").file?
    assert app.join("db/setup.rb").file?
    assert app.join(".sqlpkg/.keep").file?
    assert app.join("public/favicon.ico").file?
    assert app.join("public/icon.svg").file?
    assert app.join("public/apple-touch-icon.png").file?
    assert_equal RUBY_VERSION, app.join(".ruby-version").read.chomp
    assert app.join("bin/dev").executable?
    assert app.join("bin/zee").executable?
    assert app.join("bin/scripts").executable?
    assert app.join("bin/styles").executable?
    refute app.join("config/secrets/development.key").world_readable?
    refute app.join("config/secrets/test.key").world_readable?

    # Expect valid json files
    assert_instance_of Hash,
                       JSON.parse(
                         app.join("config/secrets/development.key").read
                       )
    assert_instance_of Hash,
                       JSON.parse(app.join("config/secrets/test.key").read)
  end

  test "applies template" do
    create_file "tmp/template.rb", <<~RUBY
      File.write("root.txt", Dir.pwd)
    RUBY

    app = Pathname("tmp/app")
    generator = Zee::Generators::App.new
    generator.options = {
      database: "sqlite",
      js: "typescript",
      css: "tailwind",
      test: "minitest",
      template: "tmp/template.rb",
      skip_bundle: true,
      skip_npm: true
    }
    generator.destination_root = app

    capture { generator.invoke_all }

    assert app.join("root.txt").file?
    assert_equal app.expand_path.to_s, app.join("root.txt").read
  end

  test "skips bundle install" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {
      skip_bundle: true,
      skip_npm: true,
      database: "sqlite",
      js: "typescript",
      css: "tailwind"
    }
    generator.destination_root = app
    out = nil

    Dir.chdir(app) do
      capture { generator.invoke_all } => {out:}
    end

    refute_includes out, "bundle install"
  end

  test "uses rspec as the test framework" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {
      skip_bundle: true,
      skip_npm: true,
      database: "sqlite",
      js: "typescript",
      css: "tailwind",
      test: "rspec"
    }
    generator.destination_root = app

    Dir.chdir(app) do
      capture { generator.invoke_all }
    end

    assert app.join("spec/spec_helper.rb").file?
    assert app.join("spec/requests/pages_spec.rb").file?
    assert app.join("spec/features/pages_spec.rb").file?
  end

  test "uses sqlite" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {
      database: "sqlite",
      js: "typescript",
      css: "tailwind",
      skip_npm: true,
      skip_bundle: true
    }
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
    generator.options = {
      database: "postgresql",
      js: "typescript",
      css: "tailwind",
      skip_npm: true,
      skip_bundle: true
    }
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
    generator.options = {
      database: "mysql",
      js: "typescript",
      css: "tailwind",
      skip_npm: true,
      skip_bundle: true
    }
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
    generator.options = {
      database: "mariadb",
      js: "typescript",
      css: "tailwind",
      skip_npm: true,
      skip_bundle: true
    }
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

  test "uses js" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {
      database: "sqlite",
      js: "js",
      css: "tailwind",
      skip_npm: true,
      skip_bundle: true
    }
    generator.destination_root = app

    Dir.chdir(app) do
      capture { generator.invoke_all }
    end

    assert app.join("app/assets/scripts/app.js").file?
    refute_includes app.join("package.json").read, "typescript"
  end

  test "fails with an unsupported database" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {database: "foo", js: "typescript", css: "tailwind"}
    generator.destination_root = app

    error = assert_raises RuntimeError do
      capture { generator.invoke_all }
    end

    assert_equal "Unsupported database: foo", error.message
  end

  test "fails with unsupported css option" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {database: "sqlite", js: "typescript", css: "foo"}
    generator.destination_root = app

    error = assert_raises Thor::Error do
      capture { generator.invoke_all }
    end

    assert_equal "Unsupported CSS option: \"foo\"", error.message
  end

  test "fails with unsupported js option" do
    app = Pathname("tmp")
    generator = Zee::Generators::App.new
    generator.options = {database: "sqlite", js: "foo", css: "css"}
    generator.destination_root = app

    error = assert_raises Thor::Error do
      capture { generator.invoke_all }
    end

    assert_equal "Unsupported JS option: \"foo\"", error.message
  end
end
