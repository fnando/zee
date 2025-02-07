# frozen_string_literal: true

require "test_helper"

class AppTest < Minitest::Test
  setup { FileUtils.rm_rf("tmp/app") }
  teardown { FileUtils.rm_rf("tmp/app") }

  test "generates new app" do
    app = Pathname("tmp/app")

    out, _ = capture_subprocess_io { Zee::CLI.start(["new", "tmp/app"]) }

    assert app.join(".gitignore").file?
    assert app.join(".rubocop.yml").file?
    assert app.join(".ruby-version").file?
    assert app.join("app/controllers/base.rb").file?
    assert app.join("app/controllers/pages.rb").file?
    assert app.join("app/views/layouts/application.html.erb").file?
    assert app.join("app/views/pages/home.html.erb").file?
    assert app.join("config.ru").file?
    assert app.join("config/app.rb").file?
    assert app.join("config/boot.rb").file?
    assert app.join("config/environment.rb").file?
    assert app.join("config/puma.rb").file?
    assert app.join("Gemfile").file?
    assert app.join("Procfile.dev").file?
    assert app.join("tmp/.keep").file?
    assert_equal RUBY_VERSION, app.join(".ruby-version").read.chomp
    assert_includes out, "bundle install"
  end

  test "skips bundle install" do
    out, _ = capture_subprocess_io { Zee::CLI.start(["new", "tmp/app", "-B"]) }

    refute_includes out, "bundle install"
  end
end
