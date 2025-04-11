# frozen_string_literal: true

require "test_helper"

class ErrorsTest < Minitest::Test
  test "generates human attribute name for anonymous classes" do
    assert_equal "full name",
                 Zee::Model::Errors.new(Class.new)
                                   .human_attribute_name(:full_name)
  end

  test "iterates over errors" do
    errors = Zee::Model::Errors.new(nil)
    errors.add(:name, :blank, message: "can't be blank")
    actual = {}
    expected = {name: ["can't be blank"]}

    errors.each {|attr, list| actual[attr] = list }

    assert_equal expected, actual
  end

  test "has errors" do
    errors = Zee::Model::Errors.new(nil)
    errors.add(:name, :blank, message: "can't be blank")

    assert errors.any?
  end

  test "is empty" do
    errors = Zee::Model::Errors.new(nil)

    assert_empty errors
  end
end
