# frozen_string_literal: true

require "test_helper"

class FormBuilderTest < Zee::Test
  include Zee::Test::Assertions::HTML

  let(:helpers) do
    Class.new do
      include Zee::ViewHelpers::Form

      def controller
        @controller ||= Zee::Controller.new
      end

      def capture(&)
        yield
      end
    end.new
  end

  let(:request) { Zee::Request.new(Rack::MockRequest.env_for("/")) }
  setup { request.session[Zee::CSRF_SESSION_KEY] = "abc" }
  setup { I18n.available_locales = [:en] }

  test "builds form using hash" do
    user = {name: "Jane"}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.text_field :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "form"
    assert_selector html,
                    "form>input[type=hidden][name='_authenticity_token']" \
                    "[value!='']"

    assert_selector html,
                    "form[action='/users'][method=post]>input#user_name" \
                    "[type=text][value='Jane'][name='user[name]']"
  end

  test "builds form using object" do
    user = mock(name: "Jane")

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.text_field :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "form"
    assert_selector html,
                    "form>input[type=hidden][name='_authenticity_token']" \
                    "[value!='']"

    assert_selector html,
                    "form[action='/users'][method=post]>input#user_name" \
                    "[type=text][value='Jane'][name='user[name]']"
  end

  test "renders text field" do
    user = {name: "Jane"}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.text_field :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html,
                    "input#user_name[type=text][value='Jane']" \
                    "[name='user[name]']"
  end

  test "renders color field" do
    page = {bgcolor: "#ff0"}

    template = <<~ERB
      <%= form_for page, url: "/pages/1", as: :page do |f| %>
        <%= f.color_field :bgcolor %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_selector html,
                    "input#page_bgcolor[type=color][value='#ff0']" \
                    "[name='page[bgcolor]']"
  end

  test "renders date field" do
    published_at = Time.now
    value = published_at.strftime("%Y-%m-%d")
    page = {published_at:}

    template = <<~ERB
      <%= form_for page, url: "/pages/1", as: :page do |f| %>
        <%= f.date_field :published_at %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_selector html,
                    "input#page_published_at[type=date][value='#{value}']" \
                    "[name='page[published_at]']"
  end

  test "renders datetime field" do
    published_at = Time.now
    value = published_at.iso8601
    page = {published_at:}

    template = <<~ERB
      <%= form_for page, url: "/pages/1", as: :page do |f| %>
        <%= f.datetime_field :published_at %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_selector html,
                    "input#page_published_at[type=datetime-local]" \
                    "[value='#{value}'][name='page[published_at]']"
  end

  test "renders file field" do
    page = {}

    template = <<~ERB
      <%= form_for page, url: "/pages/1", as: :page do |f| %>
        <%= f.file_field :header %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_selector html, "form[enctype='multipart/form-data']>" \
                          "input#page_header[type=file][name='page[header]']"
  end

  test "renders email field" do
    user = {email: "me@example.com"}

    template = <<~ERB
      <%= form_for user, url: "/users/1", as: :user do |f| %>
        <%= f.email_field :email %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "input#user_email[type=email][name='user[email]']" \
                          "[value='me@example.com']"
  end

  test "renders hidden field" do
    user = {ref: "ref_code"}

    template = <<~ERB
      <%= form_for user, url: "/users/1", as: :user do |f| %>
        <%= f.hidden_field :ref %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html,
                    "input[type=hidden][name='user[ref]'][value='ref_code']"
  end

  test "renders month field" do
    now = Time.now
    user = {published_at: now}

    template = <<~ERB
      <%= form_for user, url: "/users/1", as: :user do |f| %>
        <%= f.month_field :published_at %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "input[type=month][name='user[published_at]']" \
                          "[value='#{now.strftime('%Y-%m')}']"
  end

  test "renders number field" do
    product = {quantity: 5}

    template = <<~ERB
      <%= form_for product, url: "/products/1", as: :product do |f| %>
        <%= f.number_field :quantity %>
      <% end %>
    ERB

    html = render(template, locals: {product:}, request:)

    assert_selector html, "input#product_quantity[type=number]" \
                          "[name='product[quantity]'][value=5]"
  end

  test "renders password field" do
    user = {}

    template = <<~ERB
      <%= form_for user, url: "/users/1", as: :user do |f| %>
        <%= f.password_field :password %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html,
                    "input#user_password[type=password][name='user[password]']"
  end

  test "renders phone field" do
    user = {mobile_phone: "+15555555555"}

    template = <<~ERB
      <%= form_for user, url: "/users/1", as: :user do |f| %>
        <%= f.phone_field :mobile_phone %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "input#user_mobile_phone[type=tel]" \
                          "[name='user[mobile_phone]'][value='+15555555555']"
  end

  test "renders radio button" do
    page = {status: "enabled"}

    template = <<~ERB
      <%= form_for page, url: "/pages/1", as: :page do |f| %>
        <%= f.radio_button :status, "disabled" %>
        <%= f.radio_button :status, "enabled" %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_selector html, "input[type=radio]", count: 2
    assert_selector html, "input#page_status_disabled[type=radio]" \
                          "[value=disabled][name='page[status]']"
    assert_selector html, "input#page_status_enabled[type=radio]" \
                          "[value=enabled][name='page[status]']" \
                          "[checked=checked]"
  end

  test "renders search field" do
    search = {query: "ruby"}

    template = <<~ERB
      <%= form_for search, url: "/search", as: :search do |f| %>
        <%= f.search_field :query %>
      <% end %>
    ERB

    html = render(template, locals: {search:}, request:)

    assert_selector html, "input#search_query[type=search]" \
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
      <%= form_for user, url: "/users/1", as: :user do |f| %>
        <%= f.select :country, options %>
      <% end %>
    ERB

    html = render(template, locals: {user:, options:}, request:)

    assert_selector html,
                    "select#user_country[name='user[country]']>option",
                    count: 4
    assert_selector html, "option[selected]", count: 1
    assert_selector html, "option:nth-child(1)[value='']"
    assert_selector html, "option:nth-child(2)[value=CA]", text: /Canada/
    assert_selector html,
                    "option:nth-child(3)[value=BR][selected=selected]",
                    text: /Brazil/
    assert_selector html, "option:nth-child(4)[value=MX]", text: /Mexico/
  end

  test "renders textarea" do
    user = {bio: "I love Ruby"}

    template = <<~ERB
      <%= form_for user, url: "/user", as: :user do |f| %>
        <%= f.textarea :bio %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "textarea#user_bio[name='user[bio]']",
                    text: /I love Ruby/
  end

  test "renders time field" do
    now = Time.now
    event = {time: now}

    template = <<~ERB
      <%= form_for event, url: "/events/1", as: :event do |f| %>
        <%= f.time_field :time %>
      <% end %>
    ERB

    html = render(template, locals: {event:}, request:)

    assert_selector html, "input#event_time[type=time][name='event[time]']" \
                          "[value='#{now.strftime('%H:%M')}']"
  end

  test "renders url field" do
    event = {url: "https://example.com"}

    template = <<~ERB
      <%= form_for event, url: "/events/1", as: :event do |f| %>
        <%= f.url_field :url %>
      <% end %>
    ERB

    html = render(template, locals: {event:}, request:)

    assert_selector html, "input#event_url[type=url]" \
                          "[name='event[url]'][value='https://example.com']"
  end

  test "renders label with default text" do
    user = {}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.label :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "label[for=user_name]", text: "Name"
  end

  test "renders label with provided text" do
    user = {}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.label :name, "Your name" %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "label[for=user_name]", text: "Your name"
  end

  test "renders label using a block" do
    user = {}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.label :name do %>
          Your name
        <% end %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "label[for=user_name]", text: /Your name/
  end

  test "renders default label using array" do
    user = {}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.label [:foo, "bar"] %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "label[for=user_foo_bar]", text: /Bar/
  end

  test "renders submit button with default text" do
    user = {}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.submit %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "button[type=submit]", text: /Submit/
  end

  test "renders submit button with custom text" do
    user = {}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.submit "Save" %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "form>button[type=submit]", text: /Save/
  end

  test "renders checkbox" do
    user = {}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.checkbox :enabled %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html,
                    "form>input[type=hidden][value=0][name='user[enabled]']"

    assert_selector html,
                    "form>input[type=hidden][name='user[enabled]']+" \
                    "input#user_enabled[type=checkbox]" \
                    "[value=1][name='user[enabled]']"
  end

  test "checks checkbox with boolean value" do
    user = {enabled: true}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.checkbox :enabled %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html,
                    "form>input[type=hidden][value=0][name='user[enabled]']"

    assert_selector html,
                    "form>input[type=hidden][name='user[enabled]']+" \
                    "input#user_enabled[type=checkbox]" \
                    "[value=1][name='user[enabled]'][checked=checked]"
  end

  test "checks checkbox with matching value" do
    user = {enabled: "1"}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.checkbox :enabled %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html,
                    "form>input[type=hidden][value=0][name='user[enabled]']"

    assert_selector html,
                    "form>input[type=hidden][name='user[enabled]']+" \
                    "input#user_enabled[type=checkbox]" \
                    "[value=1][name='user[enabled]'][checked=checked]"
  end

  test "checks checkbox with custom values" do
    user = {enabled: "yep"}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.checkbox :enabled, checked_value: "yep", unchecked_value: "nope" %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html,
                    "form>input[type=hidden][value=nope][name='user[enabled]']"

    assert_selector html,
                    "form>input[type=hidden][name='user[enabled]']+" \
                    "input#user_enabled[type=checkbox]" \
                    "[value=yep][name='user[enabled]'][checked=checked]"
  end

  test "prevents checkbox's hidden input from being rendered" do
    user = {}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.checkbox :enabled, unchecked_value: nil %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "form>input[type=hidden][name='user[enabled]']",
                    count: 0
  end

  test "renders checkbox as an array" do
    page = {tags: ["ruby"]}

    template = <<~ERB
      <%= form_for page, url: "/pages/1", as: :page do |f| %>
        <%= f.checkbox :tags, "ruby" %>
        <%= f.checkbox :tags, "python" %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_selector html,
                    "form>input[type=hidden]:not([name=_authenticity_token])",
                    count: 0
    assert_selector html, "input[type=checkbox][checked=checked]", count: 1
    assert_selector html,
                    "input#page_tags_ruby[type=checkbox][value=ruby]" \
                    "[checked=checked]"
    assert_selector html, "input#page_tags_python[type=checkbox][value=python]"
  end

  test "renders checkbox group" do
    page = {tags: ["ruby"]}

    template = <<~ERB
      <%= form_for page, url: "/pages/1", as: :page do |f| %>
        <%= f.checkbox_group :tags, [["ruby", "Ruby"], ["rust", "Rust"]] %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_selector html, "form>.field-group", count: 2
    assert_selector html, "form>.field-group>input[checked=checked]", count: 1

    group = assert_selector(html, "form>.field-group:nth-of-type(1)")
    heading = assert_selector group,
                              ":root>input#page_tags_ruby[type=checkbox]+span"
    assert_selector heading, ":root.field-group-heading>label", text: /Ruby/

    group = assert_selector(html, "form>.field-group:nth-of-type(2)")
    heading = assert_selector group,
                              ":root>input#page_tags_rust[type=checkbox]+span"
    assert_selector heading, ":root.field-group-heading>label", text: /Rust/
  end

  test "renders checkbox group using i18n labels" do
    page = {tags: ["ruby"]}
    store_translations(
      :en,
      zee: {
        forms: {
          page: {
            tags: {
              values: {
                ruby: {label: "Ruby (.rb)"},
                rust: {label: "Rust (.rs)"}
              }
            }
          }
        }
      }
    )

    template = <<~ERB
      <%= form_for page, url: "/pages/1", as: :page do |f| %>
        <%= f.checkbox_group :tags, ["ruby", "rust"] %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_selector html, "form>.field-group", count: 2
    assert_selector html, "form>.field-group>input[checked=checked]", count: 1

    group = assert_selector(html, "form>.field-group:nth-of-type(1)")
    heading = assert_selector group,
                              ":root>input#page_tags_ruby[type=checkbox]+span"
    assert_selector heading, ":root.field-group-heading>label", text: /\.rb/

    group = assert_selector(html, "form>.field-group:nth-of-type(2)")
    heading = assert_selector group,
                              ":root>input#page_tags_rust[type=checkbox]+span"
    assert_selector heading, ":root.field-group-heading>label", text: /\.rs/
  end

  test "renders checkbox group using default labels" do
    page = {tags: ["ruby"]}

    template = <<~ERB
      <%= form_for page, url: "/pages/1", as: :page do |f| %>
        <%= f.checkbox_group :tags, ["ruby", "rust"] %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_selector html, "form>.field-group", count: 2
    assert_selector html, "form>.field-group>input[checked=checked]", count: 1

    group = assert_selector(html, "form>.field-group:nth-of-type(1)")
    heading = assert_selector group,
                              ":root>input#page_tags_ruby[type=checkbox]+span"
    assert_selector heading, ":root.field-group-heading>label", text: /Ruby/

    group = assert_selector(html, "form>.field-group:nth-of-type(2)")
    heading = assert_selector group,
                              ":root>input#page_tags_rust[type=checkbox]+span"
    assert_selector heading, ":root.field-group-heading>label", text: /Rust/
  end

  test "renders error message" do
    user = {errors: {name: ["can't be blank"]}}

    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.label :name %>
        <%= f.text_field :name %>
        <%= f.error :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "form>label.invalid"
    assert_selector html, "form>input.invalid"
    assert_selector html, "form>span.error", text: /can't be blank/
  end

  test "renders checkbox group using hints when available" do
    page = {tags: ["ruby"]}
    store_translations(
      :en,
      zee: {
        forms: {
          page: {
            tags: {
              values: {
                ruby: {
                  label: "Ruby",
                  hint: "Elegant language focused on readability and happiness."
                },
                rust: {
                  label: "Rust",
                  hint: "Fast, memory-safe systems language without garbage " \
                        "collection."
                }
              }
            }
          }
        }
      }
    )

    template = <<~ERB
      <%= form_for page, url: "/pages/1", as: :page do |f| %>
        <%= f.checkbox_group :tags, ["ruby", "rust"] %>
      <% end %>
    ERB

    html = render(template, locals: {page:}, request:)

    assert_selector html, "form>.field-group", count: 2
    assert_selector html, "form>.field-group>input[checked=checked]", count: 1

    group = assert_selector(html, "form>.field-group:nth-of-type(1)")
    heading = assert_selector group,
                              ":root>input#page_tags_ruby[type=checkbox]+span"
    assert_selector heading, ":root.field-group-heading>label", text: /Ruby/
    assert_selector heading, ":root.field-group-heading>label~.hint",
                    text: /Elegant/

    group = assert_selector(html, "form>.field-group:nth-of-type(2)")
    heading = assert_selector group,
                              ":root>input#page_tags_rust[type=checkbox]+span"
    assert_selector heading, ":root.field-group-heading>label", text: /Rust/
    assert_selector heading, ":root.field-group-heading>label~.hint",
                    text: /systems/
  end

  test "renders checkbox group field with all elements" do
    project = {
      features: %w[wikis],
      errors: {features: ["`foo` is not a valid feature"]}
    }
    store_translations(
      :en,
      zee: {
        forms: {
          project: {
            features: {
              hint: "Define which features will be available on your project",
              values: {
                wikis: {
                  label: "Wikis",
                  hint: "Wikis host documentation for your project."
                },
                issues: {
                  label: "Issues",
                  hint: "Issues integrate task tracking into your project."
                }
              }
            }
          }
        }
      }
    )

    template = <<~ERB
      <%= form_for project, url: "/projects/1", as: :project do |f| %>
        <%= f.field :features, %w[wikis issues], type: :checkbox_group %>
      <% end %>
    ERB
    html = render(template, locals: {project:}, request:)

    assert_selector html,
                    ".field.invalid>.field-info>span.label",
                    text: /Features/
    assert_selector html,
                    ".field.invalid>.field-info>.hint",
                    text: /Define which features/

    group = assert_selector html,
                            ".field>.field-controls>.field-group:nth-child(1)"
    assert_selector group, ":root>#project_features_wikis[checked=checked]"
    assert_selector group,
                    ":root>input+.field-group-heading>label",
                    text: "Wikis"
    assert_selector group,
                    ":root>input+.field-group-heading>label~.hint",
                    text: /Wikis host/

    group = assert_selector html,
                            ".field>.field-controls>.field-group:nth-child(2)"
    assert_selector group,
                    ":root>#project_features_issues:not([checked=checked])"
    assert_selector group,
                    ":root>input+.field-group-heading>label",
                    text: "Issues"
    assert_selector group,
                    ":root>input+.field-group-heading>label~.hint",
                    text: /Issues integrate/
  end

  test "renders radio field with all elements" do
    site = {theme: "light"}
    store_translations(
      :en,
      zee: {
        forms: {
          site: {
            theme: {
              hint: "Chose how the interface will look for you",
              values: {
                system: {
                  label: "Sync with system",
                  hint: "Theme will match your system active settings"
                },
                light: {
                  label: "Light Theme",
                  hint: "Bright, crisp interface with high contrast visuals."
                },
                dark: {
                  label: "Dark Theme",
                  hint: "Sleek, eye-friendly display for low-light settings."
                }
              }
            }
          }
        }
      }
    )

    template = <<~ERB
      <%= form_for site, url: "/sites/1", as: :site do |f| %>
        <%= f.field :theme, ["system", "light", "dark"], type: :radio_group %>
      <% end %>
    ERB

    html = render(template, locals: {site:}, request:)

    assert_selector html, "form>.field", count: 1
    assert_selector html, "form>.field>.field-controls>.field-group", count: 3
    assert_selector html, "form>.field input[checked=checked]", count: 1

    group = assert_selector html,
                            ".field>.field-controls>.field-group:nth-of-type(1)"
    heading = assert_selector group,
                              ":root>input#site_theme_system[type=radio]+span"
    assert_selector heading, ":root.field-group-heading>label", text: /Sync/
    assert_selector heading, ":root.field-group-heading>label~.hint",
                    text: /system/

    group = assert_selector html,
                            ".field>.field-controls>.field-group:nth-of-type(2)"
    heading = assert_selector group,
                              ":root>input#site_theme_light[checked=checked]" \
                              "[type=radio]+span"
    assert_selector heading, ":root.field-group-heading>label",
                    text: /Light Theme/
    assert_selector heading, ":root.field-group-heading>label~.hint",
                    text: /Bright/

    group = assert_selector html,
                            ".field>.field-controls>.field-group:nth-of-type(3)"
    heading = assert_selector group,
                              ":root>input#site_theme_dark[type=radio]+span"
    assert_selector heading, ":root.field-group-heading>label",
                    text: /Dark Theme/
    assert_selector heading, ":root.field-group-heading>label~.hint",
                    text: /Sleek/
  end

  test "renders radio group using hints when available" do
    site = {theme: "light"}
    store_translations(
      :en,
      zee: {
        forms: {
          site: {
            theme: {
              values: {
                system: {
                  label: "Sync with system",
                  hint: "Theme will match your system active settings"
                },
                light: {
                  label: "Light Theme",
                  hint: "Bright, crisp interface with high contrast visuals."
                },
                dark: {
                  label: "Dark Theme",
                  hint: "Sleek, eye-friendly display for low-light settings."
                }
              }
            }
          }
        }
      }
    )

    template = <<~ERB
      <%= form_for site, url: "/sites/1", as: :site do |f| %>
        <%= f.radio_group :theme, ["system", "light", "dark"] %>
      <% end %>
    ERB

    html = render(template, locals: {site:}, request:)

    assert_selector html, "form>.field-group", count: 3
    assert_selector html, "form>.field-group>input[checked=checked]", count: 1

    group = assert_selector(html, "form>.field-group:nth-of-type(1)")
    heading = assert_selector group,
                              ":root>input#site_theme_system[type=radio]+span"
    assert_selector heading, ":root.field-group-heading>label", text: /Sync/
    assert_selector heading, ":root.field-group-heading>label~.hint",
                    text: /system/

    group = assert_selector(html, "form>.field-group:nth-of-type(2)")
    heading = assert_selector group,
                              ":root>input#site_theme_light[checked=checked]" \
                              "[type=radio]+span"
    assert_selector heading, ":root.field-group-heading>label",
                    text: /Light Theme/
    assert_selector heading, ":root.field-group-heading>label~.hint",
                    text: /Bright/

    group = assert_selector(html, "form>.field-group:nth-of-type(3)")
    heading = assert_selector group,
                              ":root>input#site_theme_dark[type=radio]+span"
    assert_selector heading, ":root.field-group-heading>label",
                    text: /Dark Theme/
    assert_selector heading, ":root.field-group-heading>label~.hint",
                    text: /Sleek/
  end

  test "renders hint" do
    user = {}
    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.hint :name, "This is a hint" %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "span.hint", text: "This is a hint"
  end

  test "renders placeholder" do
    user = {}
    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.text_field :name, placeholder: "E.g. Jane" %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "input#user_name[placeholder='E.g. Jane']"
  end

  test "renders hint using i18n" do
    user = {}
    store_translations(:en,
                       zee: {forms: {user: {name: {hint: "This is a hint"}}}})
    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.hint :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "span.hint", text: "This is a hint"
  end

  test "renders label using i18n" do
    user = {}
    store_translations(:en, zee: {forms: {user: {name: {label: "Your name"}}}})
    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.label :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "label[for=user_name]", text: "Your name"
  end

  test "renders placeholder using i18n" do
    user = {}
    store_translations(:en,
                       zee: {forms: {user: {name: {placeholder: "E.g. Jane"}}}})
    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.text_field :name %>
      <% end %>
    ERB

    html = render(template, locals: {user:}, request:)

    assert_selector html, "input#user_name[name='user[name]']" \
                          "[placeholder='E.g. Jane']"
  end

  test "renders text field with all elements" do
    user = {errors: {name: ["can't be blank"]}}
    store_translations(
      :en,
      zee: {
        forms: {
          user: {
            name: {
              hint: "How users will see you"
            }
          }
        }
      }
    )
    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.field :name %>
      <% end %>
    ERB
    html = render(template, locals: {user:}, request:)

    assert_selector html, ".field.invalid>.field-info>label", text: /Name/
    assert_selector html, ".field>.field-info>label+.hint", text: /How/
    assert_selector html, ".field>.field-controls>input[type=text]"
    assert_selector html, ".field>.field-controls>input+.error", text: /can't/
  end

  test "renders text field with without hint" do
    user = {errors: {name: ["can't be blank"]}}
    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.field :name %>
      <% end %>
    ERB
    html = render(template, locals: {user:}, request:)

    assert_selector html, ".field>.field-info>label", text: /Name/
    assert_selector html, ".field>.field-info>label+.hint", count: 0
    assert_selector html, ".field>.field-controls>input[type=text]"
    assert_selector html, ".field>.field-controls>input+.error", text: /can't/
  end

  test "renders text field with without error" do
    user = {}
    template = <<~ERB
      <%= form_for user, url: "/users", as: :user do |f| %>
        <%= f.field :name %>
      <% end %>
    ERB
    html = render(template, locals: {user:}, request:)

    assert_selector html, ".field:not(.invalid)>.field-info>label", text: /Name/
    assert_selector html, ".field>.field-info>label+.hint", count: 0
    assert_selector html, ".field>.field-controls>input[type=text]"
    assert_selector html, ".field>.field-controls>input+.error", count: 0
  end
end
