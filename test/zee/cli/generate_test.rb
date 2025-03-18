# frozen_string_literal: true

require "test_helper"

class GenerateTest < Minitest::Test
  test "generates new migration" do
    app = Pathname("tmp")
    timestamp = Time.now.to_i
    out = nil

    Time.stubs(:now).returns(Time.at(timestamp))

    Dir.chdir(app) do
      capture do
        Zee::CLI.start(%w[generate migration create_users])
      end => {out:}
    end

    assert_path_exists app.join("db/migrations/#{timestamp}_create_users.rb")
    assert_includes out, "db/migrations/#{timestamp}_create_users.rb"
  end

  test "generates new controller" do
    app = Pathname("tmp")

    Dir.chdir(app) do
      capture do
        Zee::CLI.start(%w[generate controller users])
      end
    end

    assert_path_exists app.join("app/controllers/users.rb")
    assert_path_exists app.join("test/requests/users_test.rb")
  end

  test "generates new controller with actions" do
    app = Pathname("tmp")

    Dir.chdir(app) do
      capture do
        Zee::CLI.start(%w[generate controller users index show edit remove])
      end
    end

    assert_path_exists app.join("app/controllers/users.rb")

    assert_path_exists app.join("app/views/users/index.html.erb")
    assert_includes app.join("app/views/users/index.html.erb").read,
                    "Edit this template at app/views/users/index.html.erb"

    assert_path_exists app.join("app/views/users/show.html.erb")
    assert_includes app.join("app/views/users/show.html.erb").read,
                    "Edit this template at app/views/users/show.html.erb"

    assert_path_exists app.join("app/views/users/edit.html.erb")
    assert_includes app.join("app/views/users/edit.html.erb").read,
                    "Edit this template at app/views/users/edit.html.erb"

    assert_path_exists app.join("app/views/users/remove.html.erb")
    assert_includes app.join("app/views/users/remove.html.erb").read,
                    "Edit this template at app/views/users/remove.html.erb"

    assert_path_exists app.join("test/requests/users_test.rb")
  end

  test "generates new model" do
    app = Pathname("tmp")
    timestamp = Time.now.to_i
    out = nil

    Time.stubs(:now).returns(Time.at(timestamp))

    Dir.chdir(app) do
      capture do
        Zee::CLI.start(%w[generate model user])
      end => {out:}
    end

    assert_path_exists app.join("db/migrations/#{timestamp}_create_users.rb")
    assert_includes out, "db/migrations/#{timestamp}_create_users.rb"
    assert_includes app.join("db/migrations/#{timestamp}_create_users.rb").read,
                    "create_table :users do"
    assert_includes app.join("db/migrations/#{timestamp}_create_users.rb").read,
                    "primary_key :id"
    assert_path_exists app.join("app/models/user.rb")
    assert_includes out, "app/models/user.rb"
  end

  test "fails when trying to generate model with invalid name" do
    app = Pathname("tmp")
    timestamp = Time.now.to_i
    err = nil
    exit_code = 0

    Time.stubs(:now).returns(Time.at(timestamp))

    Dir.chdir(app) do
      capture do
        Zee::CLI.start(%w[generate model 1user])
      end => {err:, exit_code:}
    end

    assert_includes err, "ERROR: Invalid model name"
    assert_equal 1, exit_code
  end
end
