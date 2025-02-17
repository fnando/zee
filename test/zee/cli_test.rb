# frozen_string_literal: true

require "test_helper"

class CLITest < Minitest::Test
  test "generates new app" do
    app = Pathname("tmp/app")

    capture { Zee::CLI.start(["new", "tmp/app"]) } => {out:, exit_code:}

    assert_equal 0, exit_code
    assert_includes out, "bundle install"
    assert app.join(".ruby-version").file?
  end

  test "skips bundle install" do
    capture { Zee::CLI.start(["new", "tmp/app", "-B"]) } => {out:}

    refute_includes out, "bundle install"
  end

  test "runs tests" do
    exit_code = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture do
        Zee::CLI.start(["test"])
      end => {exit_code:}
    end

    assert_equal 0, exit_code
  end

  test "warns when there are no test files" do
    exit_code = nil
    err = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture do
        Zee::CLI.start(["test", "test/invalid_test.rb"])
      end => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err, "ERROR: No test files found."
  end

  test "runs bin for missing command" do
    exit_code = nil
    out = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture do
        Zee::CLI.start(["hello"])
      end => {exit_code:, out:}
    end

    assert_equal 0, exit_code
    assert_includes out, "Hello, world!"
  end

  test "shows help for missing command" do
    exit_code = nil
    err = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture do
        Zee::CLI.start(["missing"])
      end => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err, "ERROR: Could not find command `missing`."
  end
end
