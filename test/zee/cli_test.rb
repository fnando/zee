# frozen_string_literal: true

require "test_helper"

class CLITest < Minitest::Test
  test "lists routes" do
    exit_code = nil
    out = nil

    expected = <<~TEXT
      ------------+------------------------+------------------+----------------------------
       Verb       | Path                   | Prefix           | To
      ------------+------------------------+------------------+----------------------------
       GET        | /                      | root             | pages#home
       GET        | /custom-layout         |                  | pages#custom_layout
       GET        | /no-layout             |                  | pages#no_layout
       GET        | /controller-layout     |                  | things#show
       GET        | /missing-template      |                  | pages#missing_template
       GET        | /hello                 |                  | pages#hello
       GET        | /text                  |                  | formats#text
       GET        | /json                  |                  | formats#json
       GET        | /redirect              |                  | pages#redirect
       GET        | /redirect-error        |                  | pages#redirect_error
       GET        | /redirect-open         |                  | pages#redirect_open
       POST       | /session               |                  | sessions#create
       GET        | /session               |                  | sessions#show
       DELETE     | /session               |                  | sessions#delete
       GET        | /helpers               |                  | helpers#show
       GET        | /posts/new             | new_post         | posts#new
       POST       | /posts/new             |                  | posts#create
       GET        | /categories/new        | new_category     | categories#new
       POST       | /categories/new        |                  | categories#create
       PATCH      | /categories/new        |                  | categories#create
       GET        | /login                 | login            | login#new
       ALL        | /proc-app              | proc_app         | app.rb:36
       ALL        | /class-app             | class_app        | MyRackApp
      ------------+------------------------+------------------+----------------------------
    TEXT

    Dir.chdir("test/fixtures/sample_app") do
      capture do
        Zee::CLI.start(["routes"])
      end => {exit_code:, out:}
    end

    assert_equal 0, exit_code
    assert_equal expected, out
  end

  test "generates new app" do
    app = Pathname("tmp/app")

    capture { Zee::CLI.start(["new", "tmp/app"]) } => {out:, exit_code:}

    assert_equal 0, exit_code
    assert_includes out, "bundle install"
    assert app.join(".ruby-version").file?
  end

  test "generates new mailer" do
    app = Pathname("tmp/app")
    exit_code = nil

    capture { Zee::CLI.start(["new", "tmp/app", "-B"]) }
    Dir.chdir(app) do
      capture do
        Zee::CLI.start(%w[g mailer messages hello bye])
      end => {exit_code:}
    end

    assert_equal 0, exit_code
    assert app.join("app/mailers/messages.rb").file?
    assert app.join("app/views/messages/hello.text.erb").file?
    assert app.join("app/views/messages/hello.html.erb").file?
    assert app.join("app/views/messages/bye.text.erb").file?
    assert app.join("app/views/messages/bye.html.erb").file?
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

  test "fails when no bin/styles is found" do
    exit_code = nil
    err = nil

    Dir.chdir("tmp") do
      FileUtils.mkdir("bin")
      FileUtils.touch("bin/scripts")
      File.chmod(0o755, "bin/scripts")

      capture do
        Zee::CLI.start(["assets"])
      end => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err, "ERROR: bin/styles not found"
  end

  test "fails when no bin/scripts is found" do
    err = nil
    exit_code = nil

    Dir.chdir("tmp") do
      FileUtils.mkdir("bin")
      FileUtils.touch("bin/styles")
      File.chmod(0o755, "bin/styles")

      capture do
        Zee::CLI.start(["assets"])
      end => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err, "ERROR: bin/scripts not found"
  end

  test "fails when no bin/styles is not executable" do
    exit_code = nil
    err = nil

    FileUtils.mkdir_p("tmp/bin")
    FileUtils.touch("tmp/bin/styles")

    Dir.chdir("tmp") do
      capture do
        Zee::CLI.start(["assets"])
      end => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err, "ERROR: bin/styles is not executable"
  end

  test "fails when no bin/scripts is not executable" do
    exit_code = nil
    err = nil

    FileUtils.mkdir_p("tmp/bin")
    FileUtils.touch("tmp/bin/styles")
    File.chmod(0o755, "tmp/bin/styles")
    FileUtils.touch("tmp/bin/scripts")

    Dir.chdir("tmp") do
      capture do
        Zee::CLI.start(["assets"])
      end => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err, "ERROR: bin/scripts is not executable"
  end

  test "builds assets with digest" do
    exit_code = nil
    out = nil

    scripts = <<~BASH
      #!/usr/bin/env bash
      echo 'console.log("hello");' > public/assets/app.js
      echo "=> exported public/assets/app.js"
    BASH

    styles = <<~BASH
      #!/usr/bin/env bash
      echo 'body { font-family: sans-serif; }' > public/assets/app.css
      echo "=> exported public/assets/app.css"
    BASH

    FileUtils.mkdir_p("tmp/bin")
    FileUtils.mkdir_p("tmp/app/assets/images")
    FileUtils.mkdir_p("tmp/app/assets/fonts")
    FileUtils.mkdir_p("tmp/public/assets")
    File.write("tmp/app/assets/images/image.png", "image.png")
    File.write("tmp/app/assets/fonts/font.woff2", "font.woff2")
    File.write("tmp/bin/scripts", scripts)
    File.write("tmp/bin/styles", styles)
    FileUtils.chmod(0o755, "tmp/bin/scripts")
    FileUtils.chmod(0o755, "tmp/bin/styles")

    Dir.chdir("tmp") do
      capture do
        Zee::CLI.start(["assets"])
      end => {exit_code:, out:}
    end

    assert_equal 0, exit_code
    assert_path_exists \
      "tmp/public/assets/app-394b64b0fd9cab3020c832445614df2a.js"
    assert_path_exists \
      "tmp/public/assets/app-ff974d062358212ab3c71569650f232a.css"
    assert_path_exists \
      "tmp/public/assets/images/image-d2b5ca33bd970f64a6301fa75ae2eb22.png"
    assert_path_exists \
      "tmp/public/assets/fonts/font-591ad204f1c43e8838d3f605a9b4c74e.woff2"
    assert_includes out, "=> exported public/assets/app.js"
    assert_includes out, "=> exported public/assets/app.css"
  end

  test "builds assets with no digest" do
    exit_code = nil
    out = nil

    scripts = <<~BASH
      #!/usr/bin/env bash
      echo 'console.log("hello");' > public/assets/app.js
      echo "=> exported public/assets/app.js"
    BASH

    styles = <<~BASH
      #!/usr/bin/env bash
      echo 'body { font-family: sans-serif; }' > public/assets/app.css
      echo "=> exported public/assets/app.css"
    BASH

    FileUtils.mkdir_p("tmp/bin")
    FileUtils.mkdir_p("tmp/app/assets/images")
    FileUtils.mkdir_p("tmp/app/assets/fonts")
    FileUtils.mkdir_p("tmp/public/assets")
    File.write("tmp/app/assets/images/image.png", "image.png")
    File.write("tmp/app/assets/fonts/font.woff2", "font.woff2")
    File.write("tmp/bin/scripts", scripts)
    File.write("tmp/bin/styles", styles)
    FileUtils.chmod(0o755, "tmp/bin/scripts")
    FileUtils.chmod(0o755, "tmp/bin/styles")

    Dir.chdir("tmp") do
      capture do
        Zee::CLI.start(["assets", "--no-digest"])
      end => {exit_code:, out:}
    end

    assert_equal 0, exit_code
    assert_path_exists "tmp/public/assets/app.js"
    assert_path_exists "tmp/public/assets/app.css"
    assert_includes out, "=> exported public/assets/app.js"
    assert_includes out, "=> exported public/assets/app.css"
  end
end
