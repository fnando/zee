# frozen_string_literal: true

require "test_helper"

class ParamTest < Minitest::Test
  def create_model(name, timestamps: false, &)
    table_name = Dry::Inflector.new.pluralize(name).to_sym
    db = Sequel.connect("sqlite::memory:")

    sql = "CREATE TABLE #{table_name} (id integer primary key not null"
    sql << ", updated_at timestamp" if timestamps
    sql << ")"

    db.execute(sql)

    Class.new(Sequel::Model(db[table_name])) do
      plugin :param
    end
  end

  test "returns to_param attribute" do
    now = Time.now
    Time.stubs(:now).returns(now)

    assert_equal 1, create_model("user").create.to_param
  end

  test "returns overridden attribute" do
    user_class = create_model("user")
    admin_class = Class.new(user_class) do
      def to_param
        "user-#{id}"
      end
    end
    now = Time.now
    Time.stubs(:now).returns(now)

    assert_equal "user-1", admin_class.create.to_param
  end
end
