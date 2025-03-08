# frozen_string_literal: true

module Zee
  module Middleware
    class RequestLogger
      using Zee::Core::Numeric
      using Zee::Core::String::Colored
      using Zee::Core::String

      def initialize(app)
        @app = app
      end

      def call(env)
        return @app.call(env) unless Zee.app.config.enable_instrumentation

        # Process the request.
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        status, headers, body = @app.call(env)
        duration =
          (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).duration

        logger = Zee.app.config.logger
        request = Request.new(env)
        store = RequestStore.store[:instrumentation]
        props = prepare_props(store)

        props[:params] = request.params if request.params.any?

        # The order of keys is important and determines the order of the output.
        props = {handler: props.delete(:route)}.merge(props)
        props[:database] = database_log(store)
        props[:status] = "#{status} #{Rack::Utils::HTTP_STATUS_CODES[status]}"

        logger.debug("")
        logger.debug do
          "#{request.request_method} #{request.fullpath} (#{duration})"
            .colored(:magenta)
        end

        props.each do |key, value|
          colored_key = key.to_s.humanize.colored(:cyan)

          case key
          when :partials
            value.each {|path| logger.debug("Partial: #{path}") }
          else
            logger.debug("#{colored_key}: #{value}")
          end
        end

        [status, headers, body]
      end

      def relative_path(path)
        path.relative_path_from(Dir.pwd)
      rescue ArgumentError
        # :nocov:
        path
        # :nocov:
      end

      def view_log(duration:, path:)
        duration = " (#{duration.duration})" if duration

        "#{relative_path(path)}#{duration}"
      end

      def database_log(store)
        queries = store[:sequel].count
        sql_time_spent = store[:sequel].sum(&:first)

        return "0 queries" unless queries.positive?

        "#{queries} #{queries == 1 ? 'query' : 'queries'} " \
          "(#{sql_time_spent.duration})"
      end

      def prepare_props(store)
        store[:request].each_with_object({}) do |(duration, kwargs), buffer|
          if kwargs[:partial]
            buffer[:partials] ||= []
            buffer[:partials] << view_log(duration:, path: kwargs[:partial])
          else
            kwargs.each do |key, value|
              buffer[key] =
                case value
                when Pathname
                  view_log(duration:, path: value)
                else
                  value
                end
            end
          end
        end
      end
    end
  end
end
