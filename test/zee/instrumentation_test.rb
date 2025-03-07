# frozen_string_literal: true

require "test_helper"

class InstrumentTest < Minitest::Test
  include Zee::Instrumentation

  setup { RequestStore.store.clear }

  test "instruments by group" do
    instrument :partial, path: "some_view.erb"
    instrument :partial, path: "some_partial.erb"

    store = RequestStore.store[:instrumentation][:partial]

    assert_equal 2, store.size
    assert_equal [nil, {path: "some_view.erb"}], store.first
    assert_equal [nil, {path: "some_partial.erb"}], store.last
  end

  test "tracks duration when block is provided" do
    instrument :partial, path: "some_view.erb" do
      # noop
    end

    store = RequestStore.store[:instrumentation][:partial]

    assert_equal 1, store.size
    assert_instance_of Float, store.first[0]
    assert_equal({path: "some_view.erb"}, store.first[1])
  end
end
