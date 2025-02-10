# frozen_string_literal: true

require "test_helper"

class CLITest < Minitest::Test
  test "generates new app" do
    app = Pathname("tmp/app")

    capture { Zee::CLI.start(["new", "tmp/app"]) } => {out:}

    assert_includes out, "bundle install"
    assert app.join(".ruby-version").file?
  end

  test "skips bundle install" do
    capture { Zee::CLI.start(["new", "tmp/app", "-B"]) } => {out:}

    refute_includes out, "bundle install"
  end
end
