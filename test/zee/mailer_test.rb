# frozen_string_literal: true

require "test_helper"

class MailerTest < Zee::Mailer::Test
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
    assert_includes Zee::Mailer.deliveries.first.text_part.to_s, "BODY"
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

    assert_includes Zee::Mailer.deliveries.first.html_part.to_s,
                    "BODY"
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

    assert_includes Zee::Mailer.deliveries.first.text_part.to_s,
                    "BODY"
  end

  test "renders text email" do
    root = "tmp/app/views/messages"
    FileUtils.mkdir_p(root)
    File.write("#{root}/hello.text.erb", "Hello, <%= name %>")

    mailer_class = Class.new(Zee::Mailer) do
      def self.name
        "Mailers::Messages"
      end

      def hello
        expose name: "John"
        mail to: "TO", from: "FROM", subject: "SUBJECT"
      end
    end

    Dir.chdir("tmp") { mailer_class.hello.deliver }

    assert_mail_delivered
    assert_includes Zee::Mailer.deliveries.first.text_part.to_s, "Hello, John"
  end

  test "renders html email" do
    root = "tmp/app/views/messages"
    FileUtils.mkdir_p(root)
    File.write("#{root}/hello.html.erb", "Hello, <%= name %>")

    mailer_class = Class.new(Zee::Mailer) do
      def self.name
        "Mailers::Messages"
      end

      def hello
        expose name: "John"
        mail to: "TO", from: "FROM", subject: "SUBJECT"
      end
    end

    Dir.chdir("tmp") { mailer_class.hello.deliver }

    assert_mail_delivered
    assert_includes Zee::Mailer.deliveries.first.html_part.to_s, "Hello, John"
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
    end

    Dir.chdir("tmp") { mailer_class.hello.deliver }

    assert_mail_delivered
    assert_includes Zee::Mailer.deliveries.first.html_part.to_s, "rendered html"
    assert_includes Zee::Mailer.deliveries.first.text_part.to_s, "rendered text"
  end
end
