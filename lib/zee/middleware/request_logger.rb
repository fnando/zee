# frozen_string_literal: true

module Zee
  module Middleware
    # The RequestLogger middleware logs the request and response details.
    # It logs the request path, status, headers, params, and database queries.
    #
    # @example
    #   # Output
    #   GET / (30ms)
    #   Status: 200 OK
    #   Params: {"controller"=>"home", "action"=>"index"}
    #   Database: 1 query (10ns)
    #
    class RequestLogger
      using Zee::Core::Numeric
      using Zee::Core::String::Colored
      using Zee::Core::String
      using Zee::Core::Blank

      def initialize(app)
        @app = app
      end

      def logger
        Zee.app.config.logger
      end

      def call(env)
        instrumented = Zee.app.config.enable_instrumentation?

        return @app.call(env) unless instrumented

        # Process the request.
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        status, headers, body = @app.call(env)
        duration = (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start)
        request = Request.new(env)

        log_request_path(request, duration)
        log_status(status, headers)
        log_content_type(headers)
        log_request(request)
        log_mail
        log_sequel

        [status, headers, body]
      end

      def relative_path(path)
        path.relative_path_from(Dir.pwd)
      rescue ArgumentError
        # :nocov:
        path
        # :nocov:
      end

      def log_entry(key, value, duration = nil)
        duration = "(#{duration.duration})" if duration
        key = "#{key.to_s.humanize}:".colored(:cyan)
        value = relative_path(value) if value.is_a?(Pathname)

        logger.debug [key, value, duration].compact.join(SPACE)
      end

      def log_mail
        Instrumentation.instrumentations[:mailer].each do |props|
          props => {args:, duration:}
          args => {scope:}

          case scope
          when :delivery
            log_entry(:mail_delivery, args[:mailer], duration)
          else
            log_entry("mail_#{scope}", args[:path], duration)
          end
        end
      end

      def log_request(request)
        Instrumentation.instrumentations[:request].each do |props|
          # Can't use pattern matching here, because YARD fails.
          # https://github.com/lsegal/yard/issues/1521
          args = props[:args]
          duration = props[:duration]
          scope = args[:scope]

          case scope
          when :route
            log_entry(:handler, args[:name])
          when :before_action
            log_entry(:halted_by, args[:source])
          else
            log_entry(scope, args[:path], duration)
          end
        end

        return unless request.params.any?

        log_entry(
          :params,
          ParameterFilter
            .new(Zee.app.config.filter_parameters)
            .filter(request.params)
        )
      end

      def log_request_path(request, duration)
        logger.debug("")
        logger.debug do
          "#{request.request_method} #{filter_query(request.fullpath)} " \
          "(#{duration.duration})"
            .colored(:magenta)
        end
      end

      def log_status(status, headers)
        log_entry(
          :status,
          "#{status} #{Rack::Utils::HTTP_STATUS_CODES[status]}"
        )

        log_entry(:redirected_to, headers["location"]) if headers["location"]
      end

      def log_content_type(headers)
        return unless headers["content-type"]

        log_entry(:content_type, headers["content-type"])
      end

      def log_sequel
        sequel = Instrumentation.instrumentations[:sequel]
        queries = sequel.count
        sql_time_spent = sequel.sum { _1[:duration] }

        log_entry(
          :database,
          "#{queries} #{queries == 1 ? 'query' : 'queries'}",
          sql_time_spent
        )
      end

      def filter_query(path)
        uri = URI.parse(path)
        query =
          ParameterFilter
          .new(Zee.app.config.filter_parameters)
          .filter(Rack::Utils.parse_nested_query(uri.query), mask: "filtered")
        uri.query = Rack::Utils.build_nested_query(query) unless query.blank?

        uri.to_s
      end
    end
  end
end
