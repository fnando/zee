# frozen_string_literal: true

require "test_helper"

class ModuleTest < Minitest::Test
  using Zee::Core::Module

  test "defines internal attribute reader" do
    klass = Class.new do
      internal_attr_reader :foo, :bar
    end

    instance = klass.new
    instance.instance_variable_set(:@_foo, "foo")
    instance.instance_variable_set(:@_bar, "bar")

    assert_equal "foo", instance.foo
    assert_equal "bar", instance.bar
  end
end
