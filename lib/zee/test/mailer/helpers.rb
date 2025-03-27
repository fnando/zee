# frozen_string_literal: true

module Zee
  class Test < Minitest::Test
    class Mailer < Test
      module Helpers
        # Assert that email has been delivered.
        # By default, it expects that exactly 1 email has been delivery. You can
        # also specify options that will be checked against the email.
        #
        # @param count [Integer] How many emails must've been delivered.
        # @param options [Hash] The assertion options.
        # @option options [String, Array<String>] to the `TO` recipient
        # @option options [String, Array<String>] from the `FROM` recipient
        # @option options [String, Array<String>] bcc the `BCC` recipients
        # @option options [String, Array<String>] cc the `CC` recipients
        # @option options [String, Array<String>] return_path the `RETURN_PATH`
        #                                         recipients
        # @option options [Hash] headers Other headers that have been set.
        # @option options [Hash] attachments All the attachments that have been
        #                                    added to the email.
        #
        # @example
        #   # asserts that exactly 1 email has been delivered
        #   assert_mail_delivered
        #
        #   # asserts that exactly 1 email has been delivered with the following
        #   # options
        #   assert_mail_delivered to: "to@example.com",
        #                         from: "from@example.com",
        #                         subject: "Your login link"
        def assert_mail_delivered(count: 1, **options)
          raise ArgumentError, "unsupported option: body" if options.key?(:body)

          mails = self.class.deliveries.select do |mail|
            options.empty? || match_mail_options?(mail, **options)
          end

          assert_equal count,
                       mails.size,
                       "Expected #{count} emails to be delivered, but got " \
                       "#{mails.size} (options=#{options.inspect})"
        end

        # @api private
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

              value.all? {|k, v| actual_attachments[k] == v }
            else
              mail[name].to_s == value
            end
          end
        end
      end
    end
  end
end
