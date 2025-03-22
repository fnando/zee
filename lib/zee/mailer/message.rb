# frozen_string_literal: true

module Zee
  class Mailer
    class Message < ::Mail::Message
      def initialize(mailer)
        super()
        @mailer = mailer
      end

      def deliver
        Instrumentation
          .instrument(:mailer, scope: :delivery, mailer: @mailer) { super }
      end
      alias deliver_now deliver
    end
  end
end
