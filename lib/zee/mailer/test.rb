# frozen_string_literal: true

module Zee
  class Mailer
    # Return deliveries for testing.
    def self.deliveries
      ::Mail::TestMailer.deliveries
    end

    class Test < Minitest::Test
      setup { Mail.defaults { delivery_method :test } }
      setup { Mailer.deliveries.clear }

      def assert_mail_delivered(count: 1, **options)
        raise ArgumentError, "unsupported option: body" if options.key?(:body)

        mails = Mailer.deliveries.select do |mail|
          options.empty? || match_mail_options?(mail, **options)
        end

        assert_equal count,
                     mails.size,
                     "Expected #{count} emails to be delivered, but got " \
                     "#{mails.size} (options=#{options.inspect})"
      end

      def match_mail_options?(mail, **options)
        options.all? do |name, value|
          case name
          when :to, :from, :reply_to, :bcc, :cc, :return_path
            Array(value) == Array(mail[name]).map(&:to_s)
          when :headers
            actual_headers =
              mail
              .header
              .fields
              .each_with_object({}) do |field, buffer|
                buffer[field.name] = field.value
              end

            value.all? {|key, _val| actual_headers[key] == value[key] }
          when :attachments
            actual_attachments =
              mail
              .attachments
              .each_with_object({}) do |attachment, buffer|
                buffer[attachment.filename] = attachment.read
              end

            value.all? {|key, value| actual_attachments[key] == value }
          else
            mail[name].to_s == value
          end
        end
      end
    end
  end
end
