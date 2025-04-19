# frozen_string_literal: true

require "test_helper"

class CallTest < Minitest::Test
  test "delegates arguments and block to instance" do
    klass = Class.new do
      include Zee::Call
      attr_reader :args, :kwargs

      def initialize(*args, **kwargs)
        @args = args
        @kwargs = kwargs
      end

      def call
        true
      end
    end

    instance = nil
    block = proc {|i| instance = i }

    assert klass.call(1, a: 2, &block)
    assert_instance_of klass, instance
    assert_equal [1], instance.args
    assert_equal({a: 2}, instance.kwargs)
  end
end
