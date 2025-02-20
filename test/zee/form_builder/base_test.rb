# frozen_string_literal: true

require "test_helper"

class BaseTest < Minitest::Test
  test "builds css classes" do
    form = Zee::FormBuilder::Form.new(builder: nil)

    assert_equal "foo bar", form.class_names("foo", "bar")
    assert_equal "foo bar", form.class_names("foo", nil, "bar")
    assert_equal "foo bar", form.class_names("foo", false, "bar")
    assert_equal "foo bar", form.class_names("foo", "", "bar")
    assert_equal "foo bar", form.class_names("foo", ["", "bar"])
    assert_equal "foo bar", form.class_names("foo", ["", "bar", "foo"])
    assert_equal "foo bar", form.class_names("foo", bar: true)
    assert_equal "foo bar", form.class_names("foo", bar: true, baz: false)
  end

  test "returns bare field name" do
    builder = Zee::FormBuilder.new(object: nil, url: "/")
    form = Zee::FormBuilder::Form.new(builder:)

    assert_equal "name", form.name_for(:name)
  end

  test "returns namespaced field name" do
    builder = Zee::FormBuilder.new(object: nil, url: "/", as: :user)
    form = Zee::FormBuilder::Form.new(builder:)

    assert_equal "user[name]", form.name_for(:name)
  end

  test "returns bare field name for array" do
    builder = Zee::FormBuilder.new(object: nil, url: "/")
    form = Zee::FormBuilder::Form.new(builder:)

    assert_equal "skills[]", form.name_for(:skills, array: true)
  end

  test "returns namespaced field name for array" do
    builder = Zee::FormBuilder.new(object: nil, url: "/", as: :user)
    form = Zee::FormBuilder::Form.new(builder:)

    assert_equal "user[skills][]", form.name_for(:skills, array: true)
  end

  test "infers types" do
    builder = Zee::FormBuilder.new(object: nil, url: "/", as: :user)
    form = Zee::FormBuilder::Form.new(builder:)

    assert_equal :text, form.infer_type(:name)
    assert_equal :email, form.infer_type(:email)
    assert_equal :tel, form.infer_type(:phone)
  end
end
