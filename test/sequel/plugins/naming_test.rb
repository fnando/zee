# frozen_string_literal: true

require "test_helper"

class NamingTest < Minitest::Test
  using Zee::Core::String

  def create_model(name, &)
    table_name = :"#{name}s"
    db = Sequel.connect("sqlite::memory:")
    db.execute("CREATE TABLE #{table_name} (id integer primary key not null)")

    Class.new(Sequel::Model(db[table_name])) do
      singleton_class.instance_eval do
        define_method(:name) do
          "Models::#{Zee.app.config.inflector.camelize(name)}"
        end
      end

      plugin :naming
    end
  end

  test "returns model name" do
    assert_equal "user", create_model("user").naming.singular
  end

  test "returns plural name" do
    assert_equal "users", create_model("user").naming.plural
  end
end
