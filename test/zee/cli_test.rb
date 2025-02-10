# frozen_string_literal: true

require "test_helper"

class CLITest < Minitest::Test
  test "generates new app" do
    app = Pathname("tmp/app")

    out, _ = capture_subprocess_io { Zee::CLI.start(["new", "tmp/app"]) }

    assert_includes out, "bundle install"
    assert app.join(".ruby-version").file?
  end

  test "skips bundle install" do
    out, _ = capture_subprocess_io { Zee::CLI.start(["new", "tmp/app", "-B"]) }

    refute_includes out, "bundle install"
  end
end
