# frozen_string_literal: true

require "test_helper"

class FormTest < Minitest::Test
  include Zee::Test::HTMLAssertions

  let(:helpers) do
    Class.new do
      include Zee::ViewHelpers::Form

      def capture(&)
        yield
      end
    end.new
  end

  test "renders button" do
    assert_tag helpers.button_tag,
               "button[type=button]",
               text: "Button"

    assert_tag helpers.button_tag("Submit"),
               "button[type=button]",
               text: "Submit"

    assert_tag helpers.button_tag("Reset", type: "reset"),
               "button[type=reset]",
               text: "Reset"

    button = helpers.button_tag do
      helpers.content_tag :span do
        "Click me"
      end
    end

    assert_tag button,
               "button[type=button]>span",
               text: "Click me"
  end

  test "renders button in erb context" do
    html = render <<~ERB
      <%= button_tag do %>
        <%= content_tag :span do %>
          Click me
        <% end %>
      <% end %>
    ERB

    assert_tag html,
               "button[type=button]>span",
               text: /Click me/
  end

  test "renders checkbox" do
    assert_tag helpers.check_box_tag("user[admin]"),
               "input[type=checkbox][name='user[admin]'][value=1]"
    assert_tag helpers.check_box_tag("langs[]", "ruby"),
               "input[type=checkbox][name='langs[]'][value=ruby]"
    assert_tag helpers.check_box_tag("langs[]", checked: true),
               "input[type=checkbox][name='langs[]'][checked=checked]"
  end

  test "renders color input" do
    assert_tag helpers.color_field_tag("bg"),
               "input[type=color][name=bg]"
    assert_tag helpers.color_field_tag("bg", "#f00"),
               "input[type=color][name=bg][value='#f00']"
  end

  test "renders date input" do
    assert_tag helpers.date_field_tag("dob"),
               "input[type=date][name=dob]"
    assert_tag helpers.date_field_tag("dob", "2000-01-01"),
               "input[type=date][name=dob][value='2000-01-01']"
  end

  test "renders datetime input" do
    date = Time.now.iso8601

    assert_tag helpers.datetime_field_tag("starts_at"),
               "input[type='datetime-local'][name=starts_at]"
    assert_tag helpers.datetime_field_tag("starts_at", date),
               "input[type='datetime-local'][name=starts_at][value='#{date}']"
  end

  test "renders file input" do
    assert_tag helpers.file_field_tag("avatar"), "input[type=file][name=avatar]"
  end

  test "renders form tag" do
    assert_tag helpers.form_tag(action: "/login"),
               "form[action='/login'][method=post]"

    assert_tag \
      helpers.form_tag(action: "/upload", multipart: true),
      "form[action='/upload'][method=post][enctype='multipart/form-data']"
  end

  test "renders form with block" do
    html = render <<~ERB
      <%= form_tag(action: "/posts") do %>
        <%= button_tag("Save", type: :submit) %>
      <% end %>
    ERB

    assert_tag html,
               "form[action='/posts'][method=post]>button[type=submit]",
               text: "Save"
  end

  test "renders form with authenticity token" do
    html = render <<~ERB
      <%= form_tag(action: "/posts", authenticity_token: "abc") do %>
        <%= button_tag("Save", type: :submit) %>
      <% end %>
    ERB

    assert_tag html,
               "form[action='/posts'][method=post]>input[type=hidden]" \
               "[name=authenticity_token][value=abc]"
  end

  test "renders text input" do
    html = helpers.text_field_tag("user[name]", "John Doe")

    assert_tag html, "input[type=text][name='user[name]'][value='John Doe']"
  end

  test "renders email input" do
    html = helpers.email_field_tag("user[email]", "me@example.com")

    assert_tag html,
               "input[type=email][name='user[email]'][value='me@example.com']"
    assert_tag html,
               "input[autocomplete=email][inputmode=email]"
  end

  test "renders hidden input" do
    html = helpers.hidden_field_tag("authenticity_token", "abc")

    assert_tag html, "input[type=hidden][name=authenticity_token][value=abc]"
  end

  test "renders month input" do
    assert_tag helpers.month_field_tag("starts_on"),
               "input[type=month][name=starts_on]" \
               "[value='#{Date.today.strftime('%Y-%m')}']"

    assert_tag helpers.month_field_tag("starts_on", "2000-01"),
               "input[type=month][name=starts_on][value='2000-01']"

    assert_tag helpers.month_field_tag("starts_on", Date.today),
               "input[type=month][name=starts_on]" \
               "[value='#{Date.today.strftime('%Y-%m')}']"
  end

  test "renders number input" do
    assert_tag helpers.number_field_tag("quantity"),
               "input#quantity[type=number][name=quantity]"
    assert_tag helpers.number_field_tag("quantity", 1),
               "input#quantity[type=number][name=quantity][value=1]"
    assert_tag helpers.number_field_tag("quantity", min: 1),
               "input#quantity[type=number][name=quantity][min=1]"
    assert_tag helpers.number_field_tag("quantity", max: 9),
               "input#quantity[type=number][name=quantity][max=9]"
    assert_tag helpers.number_field_tag("quantity", step: 5),
               "input#quantity[type=number][name=quantity][step=5]"
    assert_tag helpers.number_field_tag("quantity", in: 1...10),
               "input#quantity[type=number][name=quantity][min=1][max=9]"
  end

  test "renders password input" do
    assert_tag helpers.password_field_tag("pass"),
               "input#pass[type=password][name=pass][autocomplete=password]"
    assert_tag helpers.password_field_tag("pass", autocomplete: :new_password),
               "input#pass[type=password][name=pass][autocomplete=new-password]"
  end

  test "converts name to id" do
    assert_equal "email", helpers.name_to_id("email")
    assert_equal "user_email", helpers.name_to_id("user[email]")
  end

  test "renders label" do
    assert_tag helpers.label_tag("name"), "label[for=name]", text: "Name"

    assert_tag helpers.label_tag("full_name"),
               "label[for=full_name]",
               text: "Full name"
  end

  test "renders email input with disabled autocomplete" do
    [false, "off"].each do |autocomplete|
      html = helpers.email_field_tag(
        "user[email]",
        "me@example.com",
        autocomplete:
      )

      assert_tag html,
                 "input[type=email][name='user[email]'][value='me@example.com']"
      assert_tag html,
                 "input[autocomplete=email][inputmode=email]",
                 count: 0
    end
  end
end
