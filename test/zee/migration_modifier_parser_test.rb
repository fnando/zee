# frozen_string_literal: true

require "test_helper"

class MigrationModifierParserTest < Minitest::Test
  setup do
    Zee::MigrationModifierParser.field_mapping = nil
  end

  test "raises error for modifier without type definition" do
    error = assert_raises(Zee::MigrationModifierParser::InvalidModifierError) do
      Zee::MigrationModifierParser.call("name")
    end

    assert_equal "Invalid modifier: \"name\"", error.message
  end

  test "raises error for unsupported type" do
    error = assert_raises(Zee::MigrationModifierParser::InvalidModifierError) do
      Zee::MigrationModifierParser.call("name:json")
    end

    assert_equal "Unsupported type: \"name:json\"; add it directly to your " \
                 "migration file",
                 error.message
  end

  test "raises error for invalid modifier options" do
    error = assert_raises(Zee::MigrationModifierParser::InvalidModifierError) do
      Zee::MigrationModifierParser.call("name:string:invalid")
    end

    assert_equal "Invalid modifier: \"name:string:invalid\"", error.message
  end

  test "parses id:primary_key" do
    field = Zee::MigrationModifierParser.call("id:primary_key")

    assert_equal "id", field.name
    assert_equal "primary_key", field.sequel_type
    assert_empty field.options
  end

  test "parses name:type" do
    field = Zee::MigrationModifierParser.call("name:string")

    assert_equal "name", field.name
    assert_equal "String", field.sequel_type
    assert_empty field.options
  end

  test "parses name:null" do
    field = Zee::MigrationModifierParser.call("name:string:null")

    assert_equal "name", field.name
    assert_equal "String", field.sequel_type
    assert field.options[:null]
  end

  test "parses name:null(true)" do
    field = Zee::MigrationModifierParser.call("name:string:null(true)")

    assert_equal "name", field.name
    assert_equal "String", field.sequel_type
    assert field.options[:null]
  end

  test "parses name:null(false)" do
    field = Zee::MigrationModifierParser.call("name:string:null(false)")

    assert_equal "name", field.name
    assert_equal "String", field.sequel_type
    refute field.options[:null]
  end

  test "parses name:text" do
    field = Zee::MigrationModifierParser.call("name:text")

    assert_equal "name", field.name
    assert_equal "String", field.sequel_type
    assert field.options[:text]
  end

  test "parses name:numeric(10)" do
    field = Zee::MigrationModifierParser.call("name:numeric(10)")

    assert_equal "name", field.name
    assert_equal "BigDecimal", field.sequel_type
    assert_equal 10, field.options[:size]
  end

  test "parses name:numeric(10,2)" do
    field = Zee::MigrationModifierParser.call("name:numeric(10,2)")

    assert_equal "name", field.name
    assert_equal "BigDecimal", field.sequel_type
    assert_equal [10, 2], field.options[:size]
  end

  test "parses name:string:index" do
    field = Zee::MigrationModifierParser.call("name:string:index")

    assert_equal "name", field.name
    assert_equal "String", field.sequel_type
    assert field.options[:index]
  end

  test "parses name:string:index(unique)" do
    field = Zee::MigrationModifierParser.call("name:string:index(unique)")

    assert_equal "name", field.name
    assert_equal "String", field.sequel_type
    assert field.options[:index][:unique]
  end

  test "parses foreign_key" do
    field = Zee::MigrationModifierParser.call("user:foreign_key")

    assert_equal "user_id", field.name
    assert_equal "foreign_key", field.sequel_type
  end

  test "returns time modifier for postgres" do
    Zee::MigrationModifierParser.stubs(:pg?).returns(true)
    field = Zee::MigrationModifierParser.call("user:datetime")

    assert_equal "timestamptz", field.sequel_type
  end

  test "returns time modifier for other databases" do
    Zee::MigrationModifierParser.stubs(:pg?).returns(false)
    field = Zee::MigrationModifierParser.call("user:datetime")

    assert_equal "Time", field.sequel_type
  end
end
