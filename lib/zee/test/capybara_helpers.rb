# frozen_string_literal: true

module Zee
  class Test < Minitest::Test
    module CapybaraHelpers
      # Click email link for the given text. This will extract links from your
      # HTML part of the email. If no HTML is defined, then an exception will be
      # raised.
      #
      # The email will that will be used is the last one. To click a link on a
      # specific message, pass it as a second argument.
      #
      # @example
      #   click_email_link "Log in now"
      #   click_email_link "Log in now", Zee::Test::Mailer.deliveries.first
      #
      # @param text [String, Regexp] The text to click.
      # @param mail [Zee::Mailer::Message] The mail to use.
      def click_email_link(text, mail = Zee::Test::Mailer.deliveries.last)
        text = Regexp.escape(text) unless text.is_a?(Regexp)

        if mail.nil?
          raise Minitest::Assertion,
                "Expected an email to have been delivered; got nil"
        end

        if text.to_s.empty?
          raise Minitest::Assertion,
                "Expected text to be a non-empty String or a Regexp; " \
                "got #{text.inspect}"
        end

        html = Nokogiri::HTML(mail.html_part.decoded)
        link = html.css("a[href]").find { _1.text.strip.match?(text) }

        unless link
          raise Minitest::Assertion,
                "Couldn't find link #{text.inspect} in email\n\n" \
                "#{format_html(html)}"
        end

        visit link[:href]
      end
    end
  end
end
