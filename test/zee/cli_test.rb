# frozen_string_literal: true

require "English"
require "test_helper"

class CLITest < Minitest::Test
  PATH = ENV.fetch("PATH")

  setup do
    ENV["PATH"] = "#{File.expand_path('test/fixtures/binstubs')}:#{PATH}"
  end
  teardown { ENV["PATH"] = PATH }

  test "detects imports" do
    assert Zee::CLI.available?("minitest")
    refute Zee::CLI.available?("missing")
  end

  test "lists middleware" do
    exit_code = nil
    out = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture { Zee::CLI.start(["middleware"]) } => {exit_code:, out:}
    end

    assert_equal 0, exit_code
    assert_includes out, "Rack::Runtime\n"
    refute_includes out, "_zee_session"
  end

  test "lists middleware with arguments" do
    exit_code = nil
    out = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture do
        Zee::CLI.start(["middleware", "--with-arguments"])
      end => {exit_code:, out:}
    end

    assert_equal 0, exit_code
    assert_includes out, "Rack::Runtime\n"
    assert_includes out, "_zee_session"
  end

  test "lists routes" do
    exit_code = nil
    out = nil

    expected = <<~TEXT
      ------------+----------------------------+------------------+----------------------------------------
       Verb       | Path                       | Prefix           | To
      ------------+----------------------------+------------------+----------------------------------------
       GET        | /                          | root             | pages#home
       GET        | /slim                      |                  | pages#slim
       GET        | /custom-layout             |                  | pages#custom_layout
       GET        | /no-layout                 |                  | pages#no_layout
       GET        | /controller-layout         |                  | things#show
       GET        | /missing-template          |                  | pages#missing_template
       GET        | /hello                     |                  | pages#hello_ivar
       GET        | /text                      |                  | formats#text
       GET        | /html                      |                  | formats#html
       GET        | /to-html                   |                  | formats#html_protocol
       GET        | /xml                       |                  | formats#xml
       GET        | /to-xml                    |                  | formats#xml_protocol
       GET        | /json                      |                  | formats#json
       GET        | /locale                    |                  | locales#show
       GET        | /redirect                  |                  | pages#redirect
       GET        | /redirect-error            |                  | pages#redirect_error
       GET        | /redirect-open             |                  | pages#redirect_open
       POST       | /session                   |                  | sessions#create
       GET        | /session                   |                  | sessions#show
       DELETE     | /session                   |                  | sessions#delete
       GET        | /helpers                   |                  | helpers#show
       GET        | /feed                      |                  | feeds#show
       GET        | /no-content                |                  | pages#no_content
       GET        | /posts/new                 | new_post         | posts#new
       POST       | /posts/new                 |                  | posts#create
       GET        | /posts/:id                 | post             | posts#show
       GET        | /categories/new            | new_category     | categories#new
       POST       | /categories/new            |                  | categories#create
       PATCH      | /categories/new            |                  | categories#create
       GET        | /login                     | login            | login#new
       GET        | /messages                  | messages         | messages#index
       POST       | /messages                  |                  | messages#create
       POST       | /messages/set-keep         |                  | messages#set_keep
       POST       | /messages/set-keep-all     |                  | messages#set_keep_all
       GET        | /messages/keep             |                  | messages#keep
       GET        | /messages/keep-all         |                  | messages#keep_all
       GET        | /admin/posts               | admin_posts      | admin/posts#index
       ALL        | /old                       |                  | #<Zee::Redirect status=301 to="/">
       ALL        | /found                     |                  | #<Zee::Redirect status=302 to="/">
       ALL        | /redirect-rack-app         |                  | app.rb:22
       ALL        | /proc-app                  | proc_app         | app.rb:8
       ALL        | /class-app                 | class_app        | MyRackApp
      ------------+----------------------------+------------------+----------------------------------------
    TEXT

    Dir.chdir("test/fixtures/sample_app") do
      capture { Zee::CLI.start(["routes"]) } => {exit_code:, out:}
    end

    assert_equal 0, exit_code
    assert_equal expected, out
  end

  test "generates routes in javascript format" do
    exit_code = nil
    out = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture do
        Zee::CLI.start(["routes", "-f", "javascript"])
      end => {exit_code:, out:}
    end

    assert_equal 0, exit_code
    assert_includes out, "export function rootURL(args, options)"
    assert_includes out, "export function postURL(args, options)"
  end

  test "generates routes in typescript format" do
    exit_code = nil
    out = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture do
        Zee::CLI.start(["routes", "-f", "typescript"])
      end => {exit_code:, out:}
    end

    assert_equal 0, exit_code
    assert_includes \
      out,
      "export function rootURL(args?: Arguments, options?: Options): string"
    assert_includes \
      out,
      "export function postURL(args: { id: Argument } & Arguments, " \
      "options?: Options): string"
  end

  test "generates new app" do
    slow_test

    app = Pathname("tmp/app")

    capture { Zee::CLI.start(["new", "tmp/app"]) } => {out:, exit_code:}

    assert_equal 0, exit_code
    assert_includes out, "bundle install"
    assert_includes out, "npm install"
    assert app.join(".ruby-version").file?
  end

  test "skips bundle install" do
    capture { Zee::CLI.start(["new", "tmp/app", "-BN"]) } => {out:}

    refute_includes out, "bundle install"
  end

  test "runs tests" do
    slow_test
    exit_code = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture(shell: true) { system "../../../exe/zee test" } => {exit_code:}
    end

    assert_equal 0, exit_code
  end

  test "runs tests from dir" do
    slow_test
    exit_code = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture(shell: true) do
        system("../../../exe/zee test test/lib")
      end => {exit_code:}
    end

    assert_equal 0, exit_code
  end

  test "runs tests for specific location" do
    slow_test
    exit_code = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture(shell: true) do
        system "../../../exe/zee test test/lib/hello_test.rb:6"
      end => {exit_code:}
    end

    assert_equal 0, exit_code
  end

  test "runs failed test" do
    slow_test
    exit_code = nil
    out = nil

    create_file "tmp/test/failed_test.rb", <<~RUBY
      require "minitest/utils"

      class FailedTest < Zee::Test
        test "it fails" do
          assert false
        end
      end
    RUBY

    Dir.chdir("tmp") do
      capture(shell: true) do
        system "../exe/zee test"
      end => {exit_code:, out:}
    end

    assert_equal 1, exit_code
    assert_includes out, "1) it fails"
  end

  test "warns when there are no test files" do
    slow_test
    exit_code = nil
    err = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture(shell: true) do
        system("../../../exe/zee test test/invalid_test.rb")
      end => {exit_code:, err:}
    end

    assert_includes err, "ERROR: No test files found."
    assert_equal 1, exit_code
  end

  test "runs bin for missing command" do
    exit_code = nil
    out = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture { Zee::CLI.start(["hello"]) } => {exit_code:, out:}
    end

    assert_equal 0, exit_code
    assert_includes out, "Hello, world!"
  end

  test "shows help for missing command" do
    exit_code = nil
    err = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture { Zee::CLI.start(["missing"]) } => {exit_code:, err:}
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

      capture { Zee::CLI.start(["assets"]) } => {exit_code:, err:}
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

      capture { Zee::CLI.start(["assets"]) } => {exit_code:, err:}
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
      capture { Zee::CLI.start(["assets"]) } => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err, "ERROR: bin/styles is not executable"
  end

  test "fails when no bin/scripts is not executable" do
    slow_test
    exit_code = nil
    err = nil

    FileUtils.mkdir_p("tmp/bin")
    FileUtils.touch("tmp/bin/styles")
    File.chmod(0o755, "tmp/bin/styles")
    FileUtils.touch("tmp/bin/scripts")

    Dir.chdir("tmp") do
      capture { Zee::CLI.start(["assets"]) } => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err, "ERROR: bin/scripts is not executable"
  end

  test "fails when no bin/styles exits with non-zero status" do
    slow_test
    exit_code = nil
    err = nil

    FileUtils.mkdir_p("tmp/bin")
    File.write "tmp/bin/styles", <<~BASH
      #!/usr/bin/env bash
      exit 1
    BASH
    File.chmod(0o755, "tmp/bin/styles")
    FileUtils.touch("tmp/bin/scripts")
    File.chmod(0o755, "tmp/bin/styles")

    Dir.chdir("tmp") do
      capture { Zee::CLI.start(["assets"]) } => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err, "ERROR: bin/styles failed to run"
  end

  test "fails when no bin/scripts exits with non-zero status" do
    slow_test
    exit_code = nil
    err = nil

    FileUtils.mkdir_p("tmp/bin")
    File.write "tmp/bin/scripts", <<~BASH
      #!/usr/bin/env bash
      exit 1
    BASH
    File.chmod(0o755, "tmp/bin/scripts")
    FileUtils.touch("tmp/bin/styles")
    File.chmod(0o755, "tmp/bin/styles")

    Dir.chdir("tmp") do
      capture { Zee::CLI.start(["assets"]) } => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err, "ERROR: bin/scripts failed to run"
  end

  test "builds assets with digest" do
    slow_test
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
      capture { Zee::CLI.start(["assets"]) } => {exit_code:, out:}
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
    slow_test
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

  test "shows help for all subcommands" do
    exit_code = nil
    err = nil
    out = nil

    Dir.chdir("tmp") do
      capture { Zee::CLI.start(["new", "--help"]) } => {exit_code:, err:, out:}
    end

    assert_equal 0, exit_code
    assert_includes out, %[new PATH]
    refute_includes err, %[Unknown switches "--help"]
  end

  test "shows version" do
    capture { Zee::CLI.start(["--version"]) } => {exit_code:, out:}

    assert_equal 0, exit_code
    assert_includes out, "zee #{Zee::VERSION}"

    capture { Zee::CLI.start(["version"]) } => {exit_code:, out:}

    assert_equal 0, exit_code
    assert_includes out, "zee #{Zee::VERSION}"
  end

  test "executes command" do
    exit_code = nil
    out = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture do
        Zee::CLI.start(%w[exec mycmd])
      end => {exit_code:, out:}
    end

    assert_equal 0, exit_code
    assert_includes out, "DOTENV_LOADED=1"
  end

  test "runs ruby file" do
    slow_test

    exit_code = nil
    out = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture(shell: true) do
        system "../../../exe/zee",
               *%w[
                 run
                 lib/runners/my_runner.rb
                 lib/runners/another_runner.rb
               ]
      end => {exit_code:, out:}
    end

    assert_equal 0, exit_code
    assert_includes out, "Hello from my runner!"
    assert_includes out, "Hello from another runner!"
  end

  test "fails when running missing ruby file" do
    slow_test

    exit_code = nil
    err = nil

    Dir.chdir("test/fixtures/sample_app") do
      capture(shell: true) do
        system "../../../exe/zee",
               *%w[
                 run
                 doesnt_exist.rb
               ]
      end => {exit_code:, err:}
    end

    assert_equal 1, exit_code
    assert_includes err, "ERROR: File not found: doesnt_exist.rb"
  end
end
