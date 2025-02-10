# frozen_string_literal: true

require "test_helper"

class GenerateTest < Minitest::Test
  test "generates new migration" do
    app = Pathname("tmp")
    timestamp = Time.now.to_i

    Time.stubs(:now).returns(Time.at(timestamp))

    out, _ = Dir.chdir(app) do
      capture_subprocess_io do
        Zee::CLI.start(["generate", "migration", "--name", "create_users"])
      end
    end

    assert_path_exists app.join("db/migrations/#{timestamp}_create_users.rb")
    assert_includes out, "db/migrations/#{timestamp}_create_users.rb"
  end
end
