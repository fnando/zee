# frozen_string_literal: true

require "test_helper"

class FormBuilderTest < Zee::Test
  include Zee::Test::HTMLAssertions

  let(:helpers) do
    Class.new do
      include Zee::ViewHelpers::Form

      def capture(&)
        yield
      end
    end.new
  end

  let(:request) { Zee::Request.new(Rack::MockRequest.env_for("/")) }
  setup { request.env[Zee::ZEE_CSRF_TOKEN] = "abc" }

  test "builds form using hash" do
    user = {name: "Jane"}

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.text_field :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "form"
    assert_tag html,
               "form>input[type=hidden][name='_authenticity_token'][value=abc]"

    assert_tag html,
               "form[action='/users'][method=post]>input#user_name[type=text]" \
               "[value='Jane'][name='user[name]']"
  end

  test "builds form using object" do
    user = mock(name: "Jane")

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.text_field :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "form"
    assert_tag html,
               "form>input[type=hidden][name='_authenticity_token'][value=abc]"

    assert_tag html,
               "form[action='/users'][method=post]>input#user_name[type=text]" \
               "[value='Jane'][name='user[name]']"
  end

  test "renders text field" do
    user = {name: "Jane"}

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.text_field :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html,
               "input#user_name[type=text][value='Jane'][name='user[name]']"
  end

  test "renders color field" do
    page = {bgcolor: "#ff0"}

    template = <<~ERB
      <%= form_for page, action: "/pages/1", as: :page do |f| %>
        <%= f.color_field :bgcolor %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_tag html,
               "input#page_bgcolor[type=color][value='#ff0']" \
               "[name='page[bgcolor]']"
  end

  test "renders date field" do
    published_at = Time.now
    value = published_at.strftime("%Y-%m-%d")
    page = {published_at:}

    template = <<~ERB
      <%= form_for page, action: "/pages/1", as: :page do |f| %>
        <%= f.date_field :published_at %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_tag html,
               "input#page_published_at[type=date][value='#{value}']" \
               "[name='page[published_at]']"
  end

  test "renders datetime field" do
    published_at = Time.now
    value = published_at.iso8601
    page = {published_at:}

    template = <<~ERB
      <%= form_for page, action: "/pages/1", as: :page do |f| %>
        <%= f.datetime_field :published_at %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_tag html,
               "input#page_published_at[type=datetime-local]" \
               "[value='#{value}'][name='page[published_at]']"
  end

  test "renders file field" do
    page = {}

    template = <<~ERB
      <%= form_for page, action: "/pages/1", as: :page do |f| %>
        <%= f.file_field :header %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_tag html, "form[enctype='multipart/form-data']>" \
                     "input#page_header[type=file][name='page[header]']"
  end

  test "renders email field" do
    user = {email: "me@example.com"}

    template = <<~ERB
      <%= form_for user, action: "/users/1", as: :user do |f| %>
        <%= f.email_field :email %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "input#user_email[type=email][name='user[email]']" \
                     "[value='me@example.com']"
  end

  test "renders hidden field" do
    user = {ref: "ref_code"}

    template = <<~ERB
      <%= form_for user, action: "/users/1", as: :user do |f| %>
        <%= f.hidden_field :ref %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "input[type=hidden][name='user[ref]'][value='ref_code']"
  end

  test "renders month field" do
    now = Time.now
    user = {published_at: now}

    template = <<~ERB
      <%= form_for user, action: "/users/1", as: :user do |f| %>
        <%= f.month_field :published_at %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "input[type=month][name='user[published_at]']" \
                     "[value='#{now.strftime('%Y-%m')}']"
  end

  test "renders number field" do
    product = {quantity: 5}

    template = <<~ERB
      <%= form_for product, action: "/products/1", as: :product do |f| %>
        <%= f.number_field :quantity %>
      <% end %>
    ERB

    html = render(template, locals: {product:}, request:)

    assert_tag html, "input#product_quantity[type=number]" \
                     "[name='product[quantity]'][value=5]"
  end

  test "renders password field" do
    user = {}

    template = <<~ERB
      <%= form_for user, action: "/users/1", as: :user do |f| %>
        <%= f.password_field :password %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "input#user_password[type=password][name='user[password]']"
  end

  test "renders phone field" do
    user = {mobile_phone: "+15555555555"}

    template = <<~ERB
      <%= form_for user, action: "/users/1", as: :user do |f| %>
        <%= f.phone_field :mobile_phone %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "input#user_mobile_phone[type=tel]" \
                     "[name='user[mobile_phone]'][value='+15555555555']"
  end

  test "renders radio button" do
    page = {status: "enabled"}

    template = <<~ERB
      <%= form_for page, action: "/pages/1", as: :page do |f| %>
        <%= f.radio_button :status, "disabled" %>
        <%= f.radio_button :status, "enabled" %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_tag html, "input[type=radio]", count: 2
    assert_tag html, "input#page_status_disabled[type=radio][value=disabled]" \
                     "[name='page[status]']"
    assert_tag html, "input#page_status_enabled[type=radio][value=enabled]" \
                     "[name='page[status]'][checked=checked]"
  end

  test "renders search field" do
    search = {query: "ruby"}

    template = <<~ERB
      <%= form_for search, action: "/search", as: :search do |f| %>
        <%= f.search_field :query %>
      <% end %>
    ERB

    html = render(template, locals: {search:}, request:)

    assert_tag html, "input#search_query[type=search]" \
                     "[name='search[query]'][value='ruby']"
  end

  test "renders select field" do
    user = {country: "BR"}
    options = [
      %w[CA Canada],
      %w[BR Brazil],
      %w[MX Mexico]
    ]

    template = <<~ERB
      <%= form_for user, action: "/users/1", as: :user do |f| %>
        <%= f.select :country, options %>
      <% end %>
    ERB

    html = render(template, locals: {user:, options:}, request:)

    assert_tag html,
               "select#user_country[name='user[country]']>option",
               count: 4
    assert_tag html, "option[selected]", count: 1
    assert_tag html, "option:nth-child(1)[value='']"
    assert_tag html, "option:nth-child(2)[value=CA]", text: /Canada/
    assert_tag html,
               "option:nth-child(3)[value=BR][selected=selected]",
               text: /Brazil/
    assert_tag html, "option:nth-child(4)[value=MX]", text: /Mexico/
  end

  test "renders textarea" do
    user = {bio: "I love Ruby"}

    template = <<~ERB
      <%= form_for user, action: "/user", as: :user do |f| %>
        <%= f.textarea :bio %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "textarea#user_bio[name='user[bio]']", text: /I love Ruby/
  end

  test "renders time field" do
    now = Time.now
    event = {time: now}

    template = <<~ERB
      <%= form_for event, action: "/events/1", as: :event do |f| %>
        <%= f.time_field :time %>
      <% end %>
    ERB

    html = render(template, locals: {event:}, request:)

    assert_tag html, "input#event_time[type=time]" \
                     "[name='event[time]'][value='#{now.strftime('%H:%M')}']"
  end

  test "renders url field" do
    event = {url: "https://example.com"}

    template = <<~ERB
      <%= form_for event, action: "/events/1", as: :event do |f| %>
        <%= f.url_field :url %>
      <% end %>
    ERB

    html = render(template, locals: {event:}, request:)

    assert_tag html, "input#event_url[type=url]" \
                     "[name='event[url]'][value='https://example.com']"
  end

  test "renders label with default text" do
    user = {}

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.label :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "label[for=user_name]", text: "Name"
  end

  test "renders label with provided text" do
    user = {}

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.label :name, "Your name" %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "label[for=user_name]", text: "Your name"
  end

  test "renders label using a block" do
    user = {}

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.label :name do %>
          Your name
        <% end %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "label[for=user_name]", text: /Your name/
  end

  test "renders submit button with default text" do
    user = {}

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.submit %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "button[type=submit]", text: /Submit/
  end

  test "renders submit button with custom text" do
    user = {}

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.submit "Save" %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "form>button[type=submit]", text: /Save/
  end

  test "renders checkbox" do
    user = {}

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.checkbox :enabled %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html,
               "form>input[type=hidden][value=0][name='user[enabled]']"

    assert_tag html,
               "form>input[type=hidden][name='user[enabled]']+" \
               "input#user_enabled[type=checkbox]" \
               "[value=1][name='user[enabled]']"
  end

  test "checks checkbox with boolean value" do
    user = {enabled: true}

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.checkbox :enabled %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html,
               "form>input[type=hidden][value=0][name='user[enabled]']"

    assert_tag html,
               "form>input[type=hidden][name='user[enabled]']+" \
               "input#user_enabled[type=checkbox]" \
               "[value=1][name='user[enabled]'][checked=checked]"
  end

  test "checks checkbox with matching value" do
    user = {enabled: "1"}

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.checkbox :enabled %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html,
               "form>input[type=hidden][value=0][name='user[enabled]']"

    assert_tag html,
               "form>input[type=hidden][name='user[enabled]']+" \
               "input#user_enabled[type=checkbox]" \
               "[value=1][name='user[enabled]'][checked=checked]"
  end

  test "checks checkbox with custom values" do
    user = {enabled: "yep"}

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.checkbox :enabled, checked_value: "yep", unchecked_value: "nope" %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html,
               "form>input[type=hidden][value=nope][name='user[enabled]']"

    assert_tag html,
               "form>input[type=hidden][name='user[enabled]']+" \
               "input#user_enabled[type=checkbox]" \
               "[value=yep][name='user[enabled]'][checked=checked]"
  end

  test "renders error message" do
    user = {errors: {name: ["can't be blank"]}}

    template = <<~ERB
      <%= form_for user, action: "/users", as: :user do |f| %>
        <%= f.label :name %>
        <%= f.text_field :name %>
        <%= f.error_for :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_tag html, "form>label.invalid"
    assert_tag html, "form>input.invalid"
    assert_tag html, "form>span.error-message", text: /can't be blank/
  end
end
