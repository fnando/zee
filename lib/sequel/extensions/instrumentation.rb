# frozen_string_literal: true

require "sequel/extensions/sql_log_normalizer"

module Sequel
  module Instrumentation
    def self.normalize_sql
      @normalize_sql ||= Sequel::SQLLogNormalizer
                         .instance_method(:normalize_logged_sql)
                         .bind(nil)
    end

    def log_connection_yield(sql, *)
      return super unless Zee.app.config.enable_instrumentation

      Zee::Instrumentation.instrument(
        :sequel,
        sql: Instrumentation.normalize_sql.call(sql)
      ) { super }
    end
  end

  Database.register_extension(:instrumentation, Instrumentation)
end
