# frozen_string_literal: true

require "test_helper"

class TranslationTest < Minitest::Test
  include Zee::Test::Assertions::HTML

  setup do
    Zee.app = Zee::App.new
    Zee.app.root = Pathname("tmp")
  end

  let(:env) { Rack::MockRequest.env_for("/").merge(Zee::RACK_SESSION => {}) }
  let(:request) { Zee::Request.new(env) }
  let(:response) { Zee::Response.new }
  let(:instrumentation) { RequestStore.store[:instrumentation] }

  let(:controller_class) do
    Class.new(Zee::Controller) do
      def self.name
        "Controllers::Pages"
      end

      def home
      end
    end
  end

  def call_action
    controller_class.new(
      request:,
      response:,
      controller_name: "pages",
      action_name: "home"
    ).send(:call)
  end

  test "translates text" do
    store_translations(:en, hello: "Hello, world!")

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <p><%= t :hello %></p>
    ERB

    call_action

    assert_html response.body, "p", text: /Hello, world!/
  end

  test "translates text scoped by controller and action" do
    store_translations(:en, pages: {home: {hello: "Hello, world!"}})

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <p><%= t ".hello" %></p>
    ERB

    call_action

    assert_html response.body, "p", text: /Hello, world!/
  end

  test "translates text scoped by partial name" do
    store_translations(:en, pages: {header: {hello: "Hello, world!"}})

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= render "header" %>
    ERB

    create_file "tmp/app/views/pages/_header.html.erb", <<~ERB
      <p><%= t ".hello" %></p>
    ERB

    call_action

    assert_html response.body, "p", text: /Hello, world!/
  end

  test "keeps non-string translations intact" do
    store_translations(:en, hello: "Hello, world!")

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <p><%= t(["hello"]).first %></p>
    ERB

    call_action

    assert_html response.body, "p", text: /Hello, world!/
  end

  test "escapes text" do
    store_translations(:en, hello: "Hello, world <3")

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <p><%= t :hello %></p>
    ERB

    call_action

    assert_html response.body, "p", text: /Hello, world <3/
  end

  test "recognizes html safe text (_html suffix)" do
    store_translations(:en, hello_html: "<p>Hello, world</p>")

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= t :hello_html %>
    ERB

    call_action

    assert_html response.body, "p", text: /Hello, world/
  end

  test "recognizes html safe text (html key)" do
    store_translations(:en, hello: {html: "<p>Hello, world</p>"})

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= t "hello.html" %>
    ERB

    call_action

    assert_html response.body, "p", text: /Hello, world/
  end

  test "recognizes html safe text (html key with scope)" do
    store_translations(:en, hello: {html: "<p>Hello, world</p>"})

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= t "html", scope: :hello %>
    ERB

    call_action

    assert_html response.body, "p", text: /Hello, world/
  end

  test "returns missing translations as html node" do
    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= t "hello.html" %>
    ERB

    call_action

    assert_html response.body,
                "span.missing-translation",
                text: /Missing translation: en.hello.html/
  end

  test "raises error when raise is set" do
    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= t "hello.html", raise: true %>
    ERB

    error = assert_raises(I18n::MissingTranslationData) { call_action }

    assert_equal "Translation missing: en.hello.html", error.message
  end

  test "localizes text" do
    now = Time.now
    Time.stubs(:now).returns(now)
    store_translations(:en, time: {formats: {short: "%Y-%m-%d"}})

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <p><%= l(Time.now, format: :short) %></p>
    ERB

    call_action

    assert_html response.body, "p", text: now.strftime("%Y-%m-%d")
  end
end
