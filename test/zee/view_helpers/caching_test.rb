# frozen_string_literal: true

require "test_helper"

class CachingTest < Minitest::Test
  include Zee::Test::Assertions::HTML

  let(:store) do
    Zee::CacheStore::Redis.new(
      pool: ConnectionPool.new { ::Redis.new },
      encrypt: false,
      namespace: SecureRandom.hex(4)
    )
  end

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
end
