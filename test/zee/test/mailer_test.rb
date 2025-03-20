# frozen_string_literal: true

require "test_helper"

class MailerTest < Zee::Test::Mailer
  test "raises for missing mail method" do
    assert_raises(NoMethodError) { Zee::Mailer.hello }
  end

  test "raises assertion when providing :body" do
    error = assert_raises(ArgumentError) do
      assert_mail_delivered body: "hello"
    end

    assert_equal "unsupported option: body", error.message
  end

  test "builds email" do
    mailer_class = Class.new(Zee::Mailer) do
      def hello
        mail to: "TO",
             from: "FROM",
             subject: "SUBJECT",
             body: "BODY",
             reply_to: "REPLY_TO",
             cc: "CC",
             bcc: "BCC",
             return_path: "RETURN_PATH",
             headers: {x_custom: "CUSTOM"},
             attachments: {"hello.txt" => "hello"}
      end
    end

    mailer_class.hello.deliver

    assert_mail_delivered to: "TO",
                          from: "FROM",
                          bcc: "BCC",
                          cc: "CC",
                          return_path: "RETURN_PATH",
                          subject: "SUBJECT",
                          headers: {"x-custom" => "CUSTOM"},
                          attachments: {"hello.txt" => "hello"}
    assert_includes mail_deliveries.first.text_part.to_s, "BODY"
  end

  test "builds email with html part" do
    mailer_class = Class.new(Zee::Mailer) do
      def hello
        mail to: "TO",
             from: "FROM",
             subject: "SUBJECT",
             body: "BODY",
             type: :html
      end
    end

    mailer_class.hello.deliver

    assert_includes mail_deliveries.first.html_part.to_s, "BODY"
  end

  test "builds email with text part" do
    mailer_class = Class.new(Zee::Mailer) do
      def hello
        mail to: "TO",
             from: "FROM",
             subject: "SUBJECT",
             body: "BODY",
             type: :text
      end
    end

    mailer_class.hello.deliver

    assert_includes mail_deliveries.first.text_part.to_s,
                    "BODY"
  end

  test "renders text email" do
    root = "tmp/app/views/messages"
    FileUtils.mkdir_p(root)
    File.write("#{root}/hello.text.erb", "Hello, <%= @name %>")

    mailer_class = Class.new(Zee::Mailer) do
      def self.name
        "Mailers::Messages"
      end

      def hello
        @name = "John"
        mail to: "TO", from: "FROM", subject: "SUBJECT"
      end

      def view_paths
        [Pathname("tmp/app/views").expand_path]
      end
    end

    mailer_class.hello.deliver

    assert_mail_delivered
    assert_includes mail_deliveries.first.text_part.to_s, "Hello, John"
  end

  test "renders html email" do
    root = "tmp/app/views/messages"
    FileUtils.mkdir_p(root)
    File.write("#{root}/hello.html.erb", "Hello, <%= @name %>")

    mailer_class = Class.new(Zee::Mailer) do
      def self.name
        "Mailers::Messages"
      end

      def hello
        @name = "John"
        mail to: "TO", from: "FROM", subject: "SUBJECT"
      end

      def view_paths
        [Pathname("tmp/app/views").expand_path]
      end
    end

    mailer_class.hello.deliver

    assert_mail_delivered
    assert_includes mail_deliveries.first.html_part.to_s, "Hello, John"
  end

  test "renders multipart email" do
    root = "tmp/app/views/messages"
    FileUtils.mkdir_p(root)
    File.write("#{root}/hello.html.erb", "rendered html")
    File.write("#{root}/hello.text.erb", "rendered text")

    mailer_class = Class.new(Zee::Mailer) do
      def self.name
        "Mailers::Messages"
      end

      def hello
        mail to: "TO", from: "FROM", subject: "SUBJECT"
      end

      def view_paths
        [Pathname("tmp/app/views").expand_path]
      end
    end

    mailer_class.hello.deliver

    assert_mail_delivered
    assert_includes mail_deliveries.first.html_part.to_s, "rendered html"
    assert_includes mail_deliveries.first.text_part.to_s, "rendered text"
  end

  test "renders layout file" do
    views = Pathname("tmp/app/views")
    layouts = views.join("layouts")
    messages = views.join("messages")

    [layouts, messages].map(&:mkpath)

    layouts.join("mailer.html.erb").write("html layout: <%= yield %>")
    layouts.join("mailer.text.erb").write("text layout: <%= yield %>")
    messages.join("hello.html.erb").write("rendered html")
    messages.join("hello.text.erb").write("rendered text")

    mailer_class = Class.new(Zee::Mailer) do
      def self.name
        "Mailers::Messages"
      end

      def hello
        mail to: "TO", from: "FROM", subject: "SUBJECT"
      end

      def view_paths
        [Pathname("tmp/app/views").expand_path]
      end
    end

    mailer_class.hello.deliver

    assert_mail_delivered
    assert_includes mail_deliveries.first.html_part.to_s,
                    "html layout: rendered html"
    assert_includes mail_deliveries.first.text_part.to_s,
                    "text layout: rendered text"
  end

  test "fails when no body has been set" do
    mailer_class = Class.new(Zee::Mailer) do
      def self.name
        "Mailers::Messages"
      end

      def hello
        mail to: "TO", from: "FROM", subject: "SUBJECT"
      end

      def view_paths
        [Pathname("tmp/app/views").expand_path]
      end
    end

    error = assert_raises(Zee::Mailer::MissingTemplateError) do
      mailer_class.hello.deliver
    end

    assert_equal "couldn't find template for messages#hello", error.message
  end

  test "makes route helpers available" do
    Zee.app.routes.default_url_options = {
      host: "example.com",
      protocol: "http"
    }

    Dir.chdir("test/fixtures/sample_app") do
      Mailers::Mailer.login("to@example.com").deliver
    end

    assert_mail_delivered
    assert_includes mail_deliveries.first.text_part.to_s,
                    "http://example.com/login"
  end
end
