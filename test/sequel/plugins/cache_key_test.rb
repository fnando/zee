# frozen_string_literal: true

require "test_helper"

class CacheKeyTest < Minitest::Test
  def create_model(name, timestamps: false, &)
    table_name = Dry::Inflector.new.pluralize(name).to_sym
    db = Sequel.connect("sqlite::memory:")

    sql = "CREATE TABLE #{table_name} (id integer primary key not null"
    sql << ", updated_at timestamp" if timestamps
    sql << ")"

    db.execute(sql)

    Class.new(Sequel::Model(db[table_name])) do
      singleton_class.instance_eval do
        define_method(:name) do
          "Models::#{Zee.app.config.inflector.camelize(name)}"
        end
      end

      plugin :cache_key
    end
  end

  test "returns cache key" do
    now = Time.now
    Time.stubs(:now).returns(now)

    assert_equal "users/1", create_model("user").create.cache_key
    assert_equal "users/1/#{now.to_i}",
                 create_model("user", timestamps: true).create.cache_key
  end
end
