# frozen_string_literal: true

require "test_helper"

class InputTest < Minitest::Test
  include Zee::Test::HTML

  let(:object) { {name: "John"} }

  test "renders basic input" do
    form = Zee::FormBuilder.new(object:, url: "/", as: :user) do
      text_field(:name)
    end

    assert_tag render(form),
               "input",
               count: 1,
               name: "user[name]",
               type: "text",
               value: "John",
               id: "user-name"
  end

  test "renders data attributes" do
    form = Zee::FormBuilder.new(object:, url: "/", as: :user) do
      text_field(:name, data: {foo: "bar"})
    end

    assert_tag render(form),
               "input",
               count: 1,
               id: "user-name",
               "data-foo" => "bar"
  end
end
