# frozen_string_literal: true

require "test_helper"

class CachingTest < Minitest::Test
  include Zee::Test::Assertions::HTML

  let(:store) do
    Zee::CacheStore::Redis.new(
      pool: ConnectionPool.new { ::Redis.new },
      encrypt: false
    )
  end

  setup { store.clear }
  setup { Zee.app.config.set(:cache, store) }

  test "caches content indefinitely" do
    slow_test

    count = 0
    counter = -> { count += 1 }

    template = <<~ERB
      <%= cache(:count) do %>
        <span><%= counter.call %></span>
      <% end %>
    ERB

    html = render(template, locals: {counter:})

    assert_selector html, "span", text: "1"

    html = render(template, locals: {counter:})

    assert_selector html, "span", text: "1"
  end

  test "caches content for a second" do
    slow_test

    count = 0
    counter = -> { count += 1 }

    template = <<~ERB
      <%= cache(:count, expires_in: 1) do %>
        <span><%= counter.call %></span>
      <% end %>
    ERB

    html = render(template, locals: {counter:})

    assert_selector html, "span", text: "1"

    sleep 1.001
    html = render(template, locals: {counter:})

    assert_selector html, "span", text: "2"
  end

  test "uses cache key from provided object" do
    slow_test

    user = stub(id: 1, cache_key: "users/1")

    template = <<~ERB
      <%= cache(user) do %>
        <span>hello</span>
      <% end %>
    ERB

    digest = Digest::MD5.hexdigest(template)
    html = render(template, locals: {user:})
    cached = store.pool.with {|r| r.get("views:#{digest}:#{user.cache_key}") }

    assert_equal(html, JSON.parse(cached))
  end

  test "uses object when cache key is not available" do
    slow_test

    user = stub(id: 1)

    template = <<~ERB
      <%= cache(user) do %>
        <span>hello</span>
      <% end %>
    ERB

    digest = Digest::MD5.hexdigest(template)
    html = render(template, locals: {user:})
    cached = store.pool.with {|r| r.get("views:#{digest}:#{user.id}") }

    assert_equal(html, JSON.parse(cached))
  end

  test "uses primitives as key" do
    slow_test

    user = stub(id: 1)

    template = <<~ERB
      <%= cache([user, :message, "name", 1]) do %>
        <span>hello</span>
      <% end %>
    ERB

    digest = Digest::MD5.hexdigest(template)
    html = render(template, locals: {user:})
    cached = store.pool.with do |r|
      r.get("views:#{digest}:#{user.id}:message:name:1")
    end

    assert_equal(html, JSON.parse(cached))
  end

  test "fails with invalid cache key" do
    slow_test

    template = <<~ERB
      <%= cache(user) do %>
        <span>hello</span>
      <% end %>
    ERB

    user = Object.new
    error = assert_raises(ArgumentError) { render(template, locals: {user:}) }
    assert_equal "Invalid cache key type: #{user.inspect} (Object)",
                 error.message
  end
end
