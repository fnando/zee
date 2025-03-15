# frozen_string_literal: true

require "test_helper"

class FormTest < Minitest::Test
  include Zee::Test::Assertions::HTML

  let(:helpers) do
    Class.new do
      include Zee::ViewHelpers::Form

      def capture(&)
        yield
      end
    end.new
  end

  test "renders button" do
    assert_selector helpers.button_tag,
                    "button[type=button]",
                    text: "Button"

    assert_selector helpers.button_tag("Submit"),
                    "button[type=button]",
                    text: "Submit"

    assert_selector helpers.button_tag("Reset", type: "reset"),
                    "button[type=reset]",
                    text: "Reset"

    button = helpers.button_tag do
      helpers.content_tag :span do
        "Click me"
      end
    end

    assert_selector button,
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

    assert_selector html,
                    "button[type=button]>span",
                    text: /Click me/
  end

  test "renders checkbox" do
    assert_selector helpers.checkbox_tag("user[admin]"),
                    "input[type=checkbox][name='user[admin]'][value=1]"
    assert_selector helpers.checkbox_tag("langs[]", "ruby"),
                    "input[type=checkbox][name='langs[]'][value=ruby]"
    assert_selector helpers.checkbox_tag("langs[]", checked: true),
                    "input[type=checkbox][name='langs[]'][checked=checked]"
  end

  test "renders color input" do
    assert_selector helpers.color_field_tag("bg"),
                    "input[type=color][name=bg]"
    assert_selector helpers.color_field_tag("bg", "#f00"),
                    "input[type=color][name=bg][value='#f00']"
  end

  test "renders date input" do
    now = Time.now

    assert_selector helpers.date_field_tag("dob"),
                    "input[type=date][name=dob]"
    assert_selector helpers.date_field_tag("dob", "2000-01-01"),
                    "input[type=date][name=dob][value='2000-01-01']"
    assert_selector helpers.date_field_tag("dob", now),
                    "input[type=date][name=dob]" \
                    "[value='#{now.strftime('%Y-%m-%d')}']"
  end

  test "renders datetime input" do
    now = Time.now
    date = now.iso8601

    assert_selector helpers.datetime_field_tag("starts_at"),
                    "input[type='datetime-local'][name=starts_at]"
    assert_selector helpers.datetime_field_tag("starts_at", date),
                    "input[type='datetime-local'][name=starts_at]" \
                    "[value='#{date}']"
    assert_selector helpers.datetime_field_tag("starts_at", now),
                    "input[type='datetime-local'][name=starts_at]" \
                    "[value='#{date}']"
  end

  test "renders file input" do
    assert_selector helpers.file_field_tag("avatar"),
                    "input[type=file][name=avatar]"
  end

  test "renders form tag" do
    assert_selector helpers.form_tag(url: "/login", authenticity_token: "abc"),
                    "form[action='/login'][method=post]"

    assert_selector helpers.form_tag(url: "/upload",
                                     multipart: true,
                                     authenticity_token: "abc"),
                    "form[action='/upload'][method=post]" \
                    "[enctype='multipart/form-data']"
  end

  test "renders form tag when using file input" do
    html = render <<~ERB
      <%= form_tag(url: "/upload") do %>
        <%= file_field_tag(:avatar) %>
      <% end %>
    ERB

    assert_selector html, "form[action='/upload'][method=post]" \
                          "[enctype='multipart/form-data']"
  end

  test "renders form with block" do
    html = render <<~ERB
      <%= form_tag(url: "/posts") do %>
        <%= button_tag("Save", type: :submit) %>
      <% end %>
    ERB

    assert_selector html,
                    "form[action='/posts'][method=post]>button[type=submit]",
                    text: "Save"
  end

  test "renders form with authenticity token" do
    html = render <<~ERB
      <%= form_tag(url: "/posts", authenticity_token: "abc") do %>
        <%= button_tag("Save", type: :submit) %>
      <% end %>
    ERB

    assert_selector html,
                    "form[action='/posts'][method=post]>input[type=hidden]" \
                    "[name=_authenticity_token][value=abc]"
  end

  test "renders email input" do
    html = helpers.email_field_tag("user[email]", "me@example.com")

    assert_selector html,
                    "input[type=email][name='user[email]']" \
                    "[value='me@example.com']"
    assert_selector html,
                    "input[autocomplete=email][inputmode=email]"
  end

  test "renders email input with disabled autocomplete" do
    [false, "off"].each do |autocomplete|
      html = helpers.email_field_tag(
        "user[email]",
        "me@example.com",
        autocomplete:
      )

      assert_selector html,
                      "input[type=email][name='user[email]']" \
                      "[value='me@example.com']"
      assert_selector html,
                      "input[autocomplete=email][inputmode=email]",
                      count: 0
    end
  end

  test "renders hidden input" do
    html = helpers.hidden_field_tag("authenticity_token", "abc")

    assert_selector html,
                    "input[type=hidden][name=authenticity_token][value=abc]"
    assert_selector html, "input[id]", count: 0
  end

  test "renders month input" do
    assert_selector helpers.month_field_tag("starts_on"),
                    "input[type=month][name=starts_on]" \
                    "[value='#{Date.today.strftime('%Y-%m')}']"

    assert_selector helpers.month_field_tag("starts_on", "2000-01"),
                    "input[type=month][name=starts_on][value='2000-01']"

    assert_selector helpers.month_field_tag("starts_on", Date.today),
                    "input[type=month][name=starts_on]" \
                    "[value='#{Date.today.strftime('%Y-%m')}']"
  end

  test "renders number input" do
    assert_selector helpers.number_field_tag("quantity"),
                    "input#quantity[type=number][name=quantity]"
    assert_selector helpers.number_field_tag("quantity", 1),
                    "input#quantity[type=number][name=quantity][value=1]"
    assert_selector helpers.number_field_tag("quantity", min: 1),
                    "input#quantity[type=number][name=quantity][min=1]"
    assert_selector helpers.number_field_tag("quantity", max: 9),
                    "input#quantity[type=number][name=quantity][max=9]"
    assert_selector helpers.number_field_tag("quantity", step: 5),
                    "input#quantity[type=number][name=quantity][step=5]"
    assert_selector helpers.number_field_tag("quantity", in: 1...10),
                    "input#quantity[type=number][name=quantity][min=1][max=9]"
  end

  test "renders password input" do
    assert_selector helpers.password_field_tag("pass"),
                    "input#pass[type=password][name=pass]" \
                    "[autocomplete=password]"
    assert_selector \
      helpers.password_field_tag("pass", autocomplete: :new_password),
      "input#pass[type=password][name=pass]" \
      "[autocomplete=new-password]"
  end

  test "renders phone input" do
    assert_selector helpers.phone_field_tag("cel"),
                    "input#cel[type=tel][name=cel][autocomplete=tel]" \
                    "[inputmode=tel]"
    assert_selector helpers.phone_field_tag("cel", autocomplete: :tel_national),
                    "input#cel[type=tel][name=cel][autocomplete=tel-national]" \
                    "[inputmode=tel]"
  end

  test "renders radio input" do
    assert_selector helpers.radio_button_tag("confirm", "yes"),
                    "input#confirm_yes[type=radio][name=confirm][value=yes]"
    assert_selector helpers.radio_button_tag("confirm", "yes", checked: true),
                    "input#confirm_yes[type=radio][name=confirm][value=yes]" \
                    "[checked=checked]"
  end

  test "renders range input" do
    assert_selector helpers.range_field_tag("quantity"),
                    "input#quantity[type=range][name=quantity]"
    assert_selector helpers.range_field_tag("quantity", 1),
                    "input#quantity[type=range][name=quantity][value=1]"
    assert_selector helpers.range_field_tag("quantity", min: 1),
                    "input#quantity[type=range][name=quantity][min=1]"
    assert_selector helpers.range_field_tag("quantity", max: 9),
                    "input#quantity[type=range][name=quantity][max=9]"
    assert_selector helpers.range_field_tag("quantity", step: 5),
                    "input#quantity[type=range][name=quantity][step=5]"
    assert_selector helpers.range_field_tag("quantity", in: 1...10),
                    "input#quantity[type=range][name=quantity][min=1][max=9]"
  end

  test "renders search input" do
    assert_selector helpers.search_field_tag("query"),
                    "input#query[type=search][name=query]"
    assert_selector helpers.search_field_tag("query", "ruby"),
                    "input#query[type=search][name=query][value=ruby]"
  end

  test "renders select" do
    html = helpers.select_tag :languages, [[1, :ruby], [2, :rust]]

    assert_selector html, "select#languages"
    assert_selector html, "select>option", count: 3
    assert_selector html, "select>option[selected]", count: 0
    assert_selector html, "select>option[value='']", text: ""
    assert_selector html, "select>option[value=1]", text: "ruby"
    assert_selector html, "select>option[value=2]", text: "rust"
  end

  test "renders select with string" do
    html = helpers.select_tag :languages, "<option value='ruby'>ruby</option>"

    assert_selector html, "select#languages"
    assert_selector html, "select>option", count: 2
    assert_selector html, "select>option[value='']", text: ""
    assert_selector html, "select>option[value='ruby']", text: "ruby"
  end

  test "renders select with buffer" do
    html = helpers.select_tag :languages,
                              Zee::SafeBuffer.new(
                                "<option value='ruby'>ruby</option>"
                              )

    assert_selector html, "select#languages"
    assert_selector html, "select>option", count: 2
    assert_selector html, "select>option[value='']", text: ""
    assert_selector html, "select>option[value='ruby']", text: "ruby"
  end

  test "renders select with selected value" do
    html = helpers.select_tag :languages, [[1, :ruby], [2, :rust]], selected: 2

    assert_selector html, "select#languages"
    assert_selector html, "select>option", count: 3
    assert_selector html, "select>option[selected]", count: 1
    assert_selector html, "select>option[value='']", text: ""
    assert_selector html, "select>option[value=1]", text: "ruby"
    assert_selector html, "select>option[value=2][selected=selected]",
                    text: "rust"
  end

  test "renders select with multiple selected values" do
    html = helpers.select_tag :languages,
                              [[1, :ruby], [2, :rust], [3, :python]],
                              selected: [1, 3],
                              multiple: true

    assert_selector html, "select#languages"
    assert_selector html, "select>option", count: 4
    assert_selector html, "select>option[selected]", count: 2
    assert_selector html, "select>option[value='']", text: ""
    assert_selector html, "select>option[value=1][selected=selected]",
                    text: "ruby"
    assert_selector html, "select>option[value=2]", text: "rust"
    assert_selector html, "select>option[value=3][selected=selected]",
                    text: "python"
  end

  test "renders select with multiple disabled options" do
    html = helpers.select_tag :languages,
                              [[1, :ruby], [2, :rust], [3, :python]],
                              disabled_options: [1, 3],
                              multiple: true

    assert_selector html, "select#languages"
    assert_selector html, "select>option", count: 4
    assert_selector html, "select>option[disabled]", count: 2
    assert_selector html, "select>option[value='']", text: ""
    assert_selector html, "select>option[value=1][disabled=disabled]",
                    text: "ruby"
    assert_selector html, "select>option[value=2]", text: "rust"
    assert_selector html, "select>option[value=3][disabled=disabled]",
                    text: "python"
  end

  test "renders select groups" do
    html = helpers.select_tag :languages,
                              {
                                "Dynamic" => [[1, :ruby], [2, :python]],
                                "Static" => [[3, :rust]]
                              }

    assert_selector html, "select#languages"
    assert_selector html, "select option", count: 4
    assert_selector html, "select>option[selected]", count: 0
    assert_selector html, "select>option[value='']", text: ""
    assert_selector html,
                    "select>optgroup[label='Dynamic']>option:nth-child(1)" \
                    "[value=1]",
                    text: "ruby"
    assert_selector html,
                    "select>optgroup[label='Dynamic']>option:nth-child(2)" \
                    "[value=2]",
                    text: "python"
    assert_selector html,
                    "select>optgroup[label='Static']>option:nth-child(1)" \
                    "[value=3]",
                    text: "rust"
  end

  test "renders select groups with selected value" do
    html = helpers.select_tag :languages,
                              {
                                "Dynamic" => [[1, :ruby], [2, :python]],
                                "Static" => [[3, :rust]]
                              },
                              selected: 1

    assert_selector html, "select#languages"
    assert_selector html, "select option", count: 4
    assert_selector html, "select option[selected]", count: 1
    assert_selector html, "select>option[value='']", text: ""
    assert_selector html,
                    "select>optgroup[label='Dynamic']>option:nth-child(1)" \
                    "[value=1][selected=selected]",
                    text: "ruby"
    assert_selector html,
                    "select>optgroup[label='Dynamic']>option:nth-child(2)" \
                    "[value=2]",
                    text: "python"
    assert_selector html,
                    "select>optgroup[label='Static']>option:nth-child(1)" \
                    "[value=3]",
                    text: "rust"
  end

  test "renders select groups with multiple selected values" do
    html = helpers.select_tag :languages,
                              {
                                "Dynamic" => [[1, :ruby], [2, :python]],
                                "Static" => [[3, :rust]]
                              },
                              selected: [1, 3]

    assert_selector html, "select#languages"
    assert_selector html, "select option", count: 4
    assert_selector html, "select option[selected]", count: 2
    assert_selector html, "select>option[value='']", text: ""
    assert_selector html,
                    "select>optgroup[label='Dynamic']>option:nth-child(1)" \
                    "[value=1][selected=selected]",
                    text: "ruby"
    assert_selector html,
                    "select>optgroup[label='Dynamic']>option:nth-child(2)" \
                    "[value=2]",
                    text: "python"
    assert_selector html,
                    "select>optgroup[label='Static']>option:nth-child(1)" \
                    "[value=3][selected=selected]",
                    text: "rust"
  end

  test "renders select groups with multiple disabled options" do
    html = helpers.select_tag :languages,
                              {
                                "Dynamic" => [[1, :ruby], [2, :python]],
                                "Static" => [[3, :rust]]
                              },
                              disabled_options: [1, 3]

    assert_selector html, "select#languages"
    assert_selector html, "select option", count: 4
    assert_selector html, "select option[disabled]", count: 2
    assert_selector html, "select>option[value='']", text: ""
    assert_selector html,
                    "select>optgroup[label='Dynamic']>option:nth-child(1)" \
                    "[value=1][disabled=disabled]",
                    text: "ruby"
    assert_selector html,
                    "select>optgroup[label='Dynamic']>option:nth-child(2)" \
                    "[value=2]",
                    text: "python"
    assert_selector html,
                    "select>optgroup[label='Static']>option:nth-child(1)" \
                    "[value=3][disabled=disabled]",
                    text: "rust"
  end

  test "renders text area" do
    assert_selector helpers.textarea_tag("bio"), "textarea#bio"

    html = helpers.textarea_tag("bio", "hello <3")

    assert_includes html.to_s, "hello &lt;3"

    html = helpers.textarea_tag("bio", "hello <3", escape: false)

    assert_includes html.to_s, "hello <3"
  end

  test "renders text input" do
    assert_selector helpers.text_field_tag("title"),
                    "input#title[type=text][name=title]"
    assert_selector helpers.text_field_tag("title", "hello"),
                    "input#title[type=text][name=title][value=hello]"
  end

  test "renders time input" do
    now = Time.now
    time = now.strftime("%H:%M")
    time_with_secs = now.strftime("%H:%M:%S")

    assert_selector helpers.time_field_tag("when"),
                    "input#when[type=time][name=when]"
    assert_selector helpers.time_field_tag("when", "14:42"),
                    "input#when[type=time][name=when][value='14:42']"
    assert_selector \
      helpers.time_field_tag("when", "14:42", include_seconds: true),
      "input#when[type=time][name=when][value='14:42:00'][step=1]"
    assert_selector helpers.time_field_tag("when", now),
                    "input#when[type=time][name=when][value='#{time}']"
    assert_selector \
      helpers.time_field_tag("when", now, include_seconds: true),
      "input#when[type=time][name=when][value='#{time_with_secs}'][step=1]"
    assert_selector \
      helpers.time_field_tag("when", now, include_seconds: true, step: 5),
      "input#when[type=time][name=when][value='#{time_with_secs}'][step=5]"
  end

  test "renders url input" do
    assert_selector helpers.url_field_tag("blog_url"), "input" do |input|
      assert_selector input, ":root#blog_url[type=url][name=blog_url]"
      assert_selector input, ":root[autocomplete=url][autocapitalize=off]"
      assert_selector input, ":root[pattern='^https?://']"
    end
    assert_selector helpers.url_field_tag("site", "https://example.com"),
                    "input#site[type=url][name=site]" \
                    "[value='https://example.com']"
  end

  test "normalizes string to id" do
    assert_equal "email", helpers.normalize_id(:email)
    assert_equal "email", helpers.normalize_id("email")
    assert_equal "user_email", helpers.normalize_id("user[email]")
  end

  test "renders label" do
    assert_selector helpers.label_tag("name"), "label[for=name]", text: "Name"

    assert_selector helpers.label_tag("full_name"),
                    "label.label[for=full_name]",
                    text: "Full name"
  end

  test "renders label using block" do
    assert_selector helpers.label_tag("name") { "Your name" },
                    "label.label[for=name]",
                    text: "Your name"
  end

  test "renders button_to form with text" do
    html = render <<~ERB
      <%= button_to("Log out", "/logout") %>
    ERB

    assert_selector html,
                    "form.button-to[action='/logout'][method=post]>" \
                    "input[name=_authenticity_token][type=hidden]+" \
                    "button[type=submit]",
                    text: "Log out"
  end

  test "renders button_to form with block" do
    html = render <<~ERB
      <%= button_to("/logout") do %>
        <%= content_tag :span, "Log out" %>
      <% end %>
    ERB

    assert_selector html,
                    "form.button-to[action='/logout'][method=post]>" \
                    "input[name=_authenticity_token][type=hidden]+" \
                    "button[type=submit]>span",
                    text: "Log out"
  end

  test "renders button_to form with custom options" do
    html = render <<~ERB
      <%= button_to("/logout", form_options: {class: "myform"}) %>
      <%= button_to("/logout", button_options: {class: "mybutton"}) %>
    ERB

    assert_selector html, "form.myform"
    assert_selector html, "button.mybutton"
  end

  test "renders button_to form with params" do
    now = Time.now
    Time.stubs(:now).returns(now)

    html = render <<~ERB
      <%= button_to("/logout", params: {time: Time.now.iso8601}) %>
    ERB

    assert_selector html,
                    "form>input[type=hidden][name=time][value='#{now.iso8601}']"
  end
end
