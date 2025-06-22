# frozen_string_literal: true

require "test_helper"

class MiddlewareStackTest < Minitest::Test
  test "appends middleware" do
    stack = Zee::MiddlewareStack.new
    stack.use Rack::CommonLogger
    stack.use Rack::Runtime

    list = stack.to_a

    assert_equal 2, list.size
    assert_equal [Rack::CommonLogger, [], {}, nil], list[0]
    assert_equal [Rack::Runtime, [], {}, nil], list[1]
  end

  test "prepends middleware" do
    stack = Zee::MiddlewareStack.new
    stack.use Rack::CommonLogger
    stack.unshift Rack::Runtime

    list = stack.to_a

    assert_equal 2, list.size
    assert_equal [Rack::Runtime, [], {}, nil], list[0]
    assert_equal [Rack::CommonLogger, [], {}, nil], list[1]
  end

  test "clears stack" do
    stack = Zee::MiddlewareStack.new
    stack.use Rack::CommonLogger
    stack.use Rack::Runtime

    stack.clear

    assert_empty stack.to_a
  end

  test "removes middleware" do
    stack = Zee::MiddlewareStack.new
    stack.use Rack::CommonLogger
    stack.use Rack::Runtime

    stack.delete Rack::CommonLogger

    assert_equal [[Rack::Runtime, [], {}, nil]], stack.to_a
  end
end
