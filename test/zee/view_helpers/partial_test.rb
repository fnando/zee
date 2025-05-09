# frozen_string_literal: true

require "test_helper"

class PartialTest < Minitest::Test
  include Zee::Test::Assertions::HTML

  setup do
    Zee.app.root = Pathname("tmp")
    FileUtils.mkdir_p Zee.app.root.join("app/app/helpers")
  end

  let(:env) { Rack::MockRequest.env_for("/").merge(Zee::RACK_SESSION => {}) }
  let(:request) { Zee::Request.new(env) }
  let(:response) { Zee::Response.new }
  let(:instrumentation) { RequestStore.store[:instrumentation] }

  test "renders partial" do
    controller_class = Class.new(Zee::Controller) do
      def self.name
        "Controllers::Pages"
      end

      def home
      end
    end

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= render "header" %>
    ERB

    create_file "tmp/app/views/pages/_header.html.erb", <<~ERB
      <h1>Home</h1>
    ERB

    controller_class.new(
      request:,
      response:,
      controller_name: "pages",
      action_name: "home"
    ).send(:call)

    assert_selector response.body, "h1", text: /Home/
  end

  test "renders partial from parent controller" do
    parent_class = Class.new(Zee::Controller) do
      def self.name
        "Controllers::Parent"
      end
    end

    controller_class = Class.new(parent_class) do
      def self.name
        "Controllers::Pages"
      end

      def home
      end
    end

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= render "header" %>
    ERB

    create_file "tmp/app/views/parent/_header.html.erb", <<~ERB
      <h1>Home</h1>
    ERB

    controller_class.new(
      request:,
      response:,
      controller_name: "pages",
      action_name: "home"
    ).send(:call)

    assert_selector response.body, "h1", text: /Home/
  end

  test "renders partial from application" do
    controller_class = Class.new(Zee::Controller) do
      def self.name
        "Controllers::Pages"
      end

      def home
      end
    end

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= render "header" %>
    ERB

    create_file "tmp/app/views/application/_header.html.erb", <<~ERB
      <h1>Home</h1>
    ERB

    controller_class.new(
      request:,
      response:,
      controller_name: "pages",
      action_name: "home"
    ).send(:call)

    assert_selector response.body, "h1", text: /Home/
  end

  test "renders partial if in view path" do
    controller_class = Class.new(Zee::Controller) do
      def self.name
        "Controllers::Pages"
      end

      def home
      end
    end

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= render "application/header" %>
    ERB

    create_file "tmp/app/views/application/_header.html.erb", <<~ERB
      <h1>Home</h1>
    ERB

    controller_class.new(
      request:,
      response:,
      controller_name: "pages",
      action_name: "home"
    ).send(:call)

    assert_selector response.body, "h1", text: /Home/
  end

  test "renders partial with object (default name)" do
    controller_class = Class.new(Zee::Controller) do
      def self.name
        "Controllers::Pages"
      end

      def home
      end
    end

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= render "header", {title: "Home"} %>
    ERB

    create_file "tmp/app/views/pages/_header.html.erb", <<~ERB
      <h1><%= item[:title] %></h1>
    ERB

    controller_class.new(
      request:,
      response:,
      controller_name: "pages",
      action_name: "home"
    ).send(:call)

    assert_selector response.body, "h1", text: /Home/
  end

  test "renders partial with object (custom name)" do
    controller_class = Class.new(Zee::Controller) do
      def self.name
        "Controllers::Pages"
      end

      def home
      end
    end

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= render "header", {title: "Home"}, as: :meta %>
    ERB

    create_file "tmp/app/views/pages/_header.html.erb", <<~ERB
      <h1><%= meta[:title] %></h1>
    ERB

    controller_class.new(
      request:,
      response:,
      controller_name: "pages",
      action_name: "home"
    ).send(:call)

    assert_selector response.body, "h1", text: /Home/
  end

  test "renders partial with locals" do
    controller_class = Class.new(Zee::Controller) do
      def self.name
        "Controllers::Pages"
      end

      def home
      end
    end

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <%= render "header", locals: {title: "Home"} %>
    ERB

    create_file "tmp/app/views/pages/_header.html.erb", <<~ERB
      <h1><%= title %></h1>
    ERB

    controller_class.new(
      request:,
      response:,
      controller_name: "pages",
      action_name: "home"
    ).send(:call)

    assert_selector response.body, "h1", text: /Home/
  end

  test "renders partial with collection" do
    controller_class = Class.new(Zee::Controller) do
      def self.name
        "Controllers::Pages"
      end

      def home
      end
    end

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <ul>
        <%= render "item", [{desc: "Item 1"}, {desc: "Item 2"}] %>
      </ul>
    ERB

    create_file "tmp/app/views/pages/_item.html.erb", <<~ERB
      <p data-index="<%= index %>"><%= item[:desc] %></p>
    ERB

    controller_class.new(
      request:,
      response:,
      controller_name: "pages",
      action_name: "home"
    ).send(:call)

    assert_selector response.body, "p", count: 2
    assert_selector response.body, "p[data-index=0]", text: /Item 1/
    assert_selector response.body, "p[data-index=1]", text: /Item 2/
  end

  test "renders partial with collection sets first? and last?" do
    controller_class = Class.new(Zee::Controller) do
      def self.name
        "Controllers::Pages"
      end

      def home
      end
    end

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <ul>
        <%= render "item",
                   [{desc: "Item 1"}, {desc: "Item 2"}, {desc: "Item 3"}] %>
      </ul>
    ERB

    create_file "tmp/app/views/pages/_item.html.erb", <<~ERB
      <%= content_tag :p, item[:desc], class: {first: first?, last: last?} %>
    ERB

    controller_class.new(
      request:,
      response:,
      controller_name: "pages",
      action_name: "home"
    ).send(:call)

    assert_selector response.body, "p", count: 3
    assert_selector response.body, "p.first:nth-of-type(1)", text: /Item 1/
    assert_selector response.body,
                    "p:nth-of-type(2):not([class])",
                    text: /Item 2/
    assert_selector response.body, "p.last:nth-of-type(1)", text: /Item 3/
  end

  test "renders partial with collection using spacer" do
    controller_class = Class.new(Zee::Controller) do
      def self.name
        "Controllers::Pages"
      end

      def home
      end
    end

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <ul>
        <%= render "item",
                   [{desc: "Item 1"}, {desc: "Item 2"}, {desc: "Item 3"}],
                   spacer: "spacer" %>
      </ul>
    ERB

    create_file "tmp/app/views/pages/_item.html.erb", <<~ERB
      <p data-index="<%= index %>"><%= item[:desc] %></p>
    ERB

    create_file "tmp/app/views/pages/_spacer.html.erb", <<~ERB
      <hr>
    ERB

    controller_class.new(
      request:,
      response:,
      controller_name: "pages",
      action_name: "home"
    ).send(:call)

    assert_selector response.body, "p", count: 3
    assert_selector response.body, "hr", count: 2
    assert_selector response.body, "p[data-index=0]", text: /Item 1/
    assert_selector response.body, "p[data-index=1]", text: /Item 2/
    assert_selector response.body, "p[data-index=2]", text: /Item 3/
    assert_selector response.body, "p+hr+p+hr+p"

    assert_instance_of Float, instrumentation[:request][1].delete(:duration)
    assert_equal(
      {
        name: :request,
        args: {
          scope: :partial,
          path: Pathname("tmp/app/views/pages/_spacer.html.erb")
        }
      }, instrumentation[:request][1].except(:time)
    )
  end

  test "renders partial with collection using blank" do
    controller_class = Class.new(Zee::Controller) do
      def self.name
        "Controllers::Pages"
      end

      def home
      end
    end

    create_file "tmp/app/views/pages/home.html.erb", <<~ERB
      <ul>
        <%= render "item", [], spacer: "spacer", blank: "blank" %>
      </ul>
    ERB

    create_file "tmp/app/views/pages/_blank.html.erb", <<~ERB
      <li>No items</li>
    ERB

    create_file "tmp/app/views/pages/_spacer.html.erb", <<~ERB
      <hr>
    ERB

    create_file "tmp/app/views/pages/_item.html.erb", <<~ERB
      <li>Item <%= index %></li>
    ERB

    controller_class.new(
      request:,
      response:,
      controller_name: "pages",
      action_name: "home"
    ).send(:call)

    assert_selector response.body, "li", text: /No items/

    assert_instance_of Float, instrumentation[:request][0].delete(:duration)
    assert_equal(
      {
        name: :request,
        args: {
          scope: :partial,
          path: Pathname("tmp/app/views/pages/_blank.html.erb")
        }
      }, instrumentation[:request][0].except(:time)
    )
  end
end
