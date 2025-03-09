# frozen_string_literal: true

require "test_helper"

class InstrumentTest < Minitest::Test
  include Zee::Instrumentation

  setup { RequestStore.store.clear }

  test "instruments by group" do
    instrument :render, scope: :partial, path: "some_view.erb"
    instrument :render, scope: :partial, path: "some_partial.erb"

    store = RequestStore.store[:instrumentation][:render]

    assert_equal 2, store.size
    assert_equal(
      {
        name: :render,
        duration: nil,
        args: {path: "some_view.erb", scope: :partial}
      }, store.first
    )
    assert_equal(
      {
        name: :render,
        duration: nil,
        args: {path: "some_partial.erb", scope: :partial}
      }, store.last
    )
  end

  test "tracks duration when block is provided" do
    instrument :render, scope: :view, path: "some_view.erb" do
      # noop
    end

    store = RequestStore.store[:instrumentation][:render]

    assert_equal 1, store.size
    assert_instance_of Float, store.first.delete(:duration)
    assert_equal({name: :render, args: {scope: :view, path: "some_view.erb"}},
                 store.first)
  end
end
