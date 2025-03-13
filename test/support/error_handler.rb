# frozen_string_literal: true

class ErrorHandler
  Notification = Data.define(:error, :context)

  def errors
    @errors ||= []
  end

  def call(error:, context:)
    errors << Notification.new(error:, context:)
  end
end
