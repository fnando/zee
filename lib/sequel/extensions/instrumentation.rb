# frozen_string_literal: true

module Sequel
  module Instrumentation
    def execute(sql, opts = OPTS, &block)
      Zee::Instrumentation.instrument(:sequel, sql:) { super }
    end
  end

  Database.register_extension(:instrumentation, Instrumentation)
end
