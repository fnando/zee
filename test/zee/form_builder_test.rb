# frozen_string_literal: true

require "test_helper"

class FormBuilderTest < Minitest::Test
  include Zee::Test::HTML

  test "builds the default form" do
    html = render(Zee::FormBuilder.new(object: nil, url: "/"))

    assert_tag html, "form[action='/'][method='post']", count: 1
  end

  test "renders text field" do
    form = Zee::FormBuilder.new(object: nil, url: "/", as: :user) do
      field :name, label: "Name"
    end

    html = render(form)

    assert_tag html, "form[action='/'][method='post']", count: 1
    assert_tag html, "form>.field>.field--group>label", count: 1,
                                                        text: "Name",
                                                        class: "field--label"
    assert_tag html, ".field--group+input", count: 1,
                                            name: "user[name]",
                                            id: "user-name",
                                            class: "field--input"
  end

  test "renders text field with hint" do
    form = Zee::FormBuilder.new(object: nil, url: "/", as: :user) do
      field :name,
            label: "Name",
            hint: "How other users will see you."
    end

    html = render(form)

    assert_tag html,
               "form>.field>.field--group>label+span",
               count: 1,
               text: "How other users will see you.",
               class: "field--hint"
    assert_tag html, ".field--group+input", count: 1,
                                            name: "user[name]",
                                            id: "user-name",
                                            class: "field--input",
                                            type: "text"
  end

  test "renders email field" do
    form = Zee::FormBuilder.new(object: nil, url: "/", as: :user) do
      field :email, label: "E-mail"
    end

    html = render(form)

    assert_tag html, ".field--group+input", count: 1,
                                            name: "user[email]",
                                            id: "user-email",
                                            class: "field--input",
                                            type: "email",
                                            autocomplete: "email",
                                            autocapitalize: "off",
                                            inputmode: "email"
  end

  test "renders telephone field" do
    form = Zee::FormBuilder.new(object: nil, url: "/", as: :user) do
      field :phone, label: "Phone"
    end

    html = render(form)

    assert_tag html, ".field--group+input", count: 1,
                                            name: "user[phone]",
                                            id: "user-phone",
                                            class: "field--input",
                                            type: "tel",
                                            autocomplete: "tel",
                                            autocapitalize: "off",
                                            inputmode: "tel"
  end

  test "renders color field" do
    form = Zee::FormBuilder.new(object: nil, url: "/", as: :user) do
      field :color, label: "Background color"
    end

    html = render(form)

    assert_tag html, ".field--group+input", count: 1,
                                            name: "user[color]",
                                            id: "user-color",
                                            class: "field--input",
                                            type: "color"
  end

  test "renders checkbox field" do
    form = Zee::FormBuilder.new(object: nil, url: "/", as: :user) do
      field :confirmation, label: "I confirm", type: :check_box
    end

    html = render(form)

    assert_tag html,
               ".field--group+input[type=hidden]",
               count: 1,
               name: "user[confirmation]",
               value: "0"
    assert_tag html,
               "input[type=hidden]+input[type=checkbox]",
               count: 1,
               name: "user[confirmation]",
               value: "1"
  end
end
