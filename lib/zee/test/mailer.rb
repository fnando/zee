# frozen_string_literal: true

module Zee
  class Mailer
    # Returns all the emails that have been delivered in test mode.
    def self.deliveries
      ::Mail::TestMailer.deliveries
    end
  end

  class Test < Minitest::Test
    # This test class allows you to test mailer classes. It sets delivery mode
    # to `:test` and clears deliveries as a setup step.
    #
    # @example
    #   class MailerTest < Zee::Test::Mailer
    #     test "renders login email" do
    #       Mailers::Mailer.login("to@example.com").deliver
    #
    #       assert_mail_delivered subject: "Your login link",
    #                             from: "from@example.com",
    #                             to: "to@example.com"
    #       assert_selector mail.html_part.to_s,
    #                       "a[href^*='https://example.com/login/confirm']",
    #                       text: "Sign in to your account"
    #     end
    #   end
    class Mailer < Test
      include Test::Assertions::HTML
      include Helpers

      # Returns all the emails that have been delivered in test mode.
      def self.deliveries
        ::Mail::TestMailer.deliveries
      end

      # Return the app's routes.
      def routes
        @routes ||= Object.new.extend(Zee.app.routes.helpers)
      end
    end
  end
end
