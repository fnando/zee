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
        instrumented = Zee.app.config.enable_instrumentation &&
                       RequestStore.store[:instrumentation]

        return @app.call(env) unless instrumented

        # Process the request.
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        status, headers, body = @app.call(env)
        duration =
          (Process.clock_gettime(Process::CLOCK_MONOTONIC) - start).duration

        logger = Zee.app.config.logger
        request = Request.new(env)
        store = RequestStore.store[:instrumentation]
        props = prepare_props(store)

        if request.params.any?
          props[:params] = ParameterFilter.new(Zee.app.config.filter_parameters)
                                          .filter(request.params)
        end

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
            value.each do |path|
              logger.debug("#{'Partial'.colored(:cyan)}: #{path}")
            end
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
        return unless store&.key?(:sequel)

        queries = store[:sequel].count
        sql_time_spent = store[:sequel].sum { _1[:duration] }

        return "0 queries" unless queries.positive?

        "#{queries} #{queries == 1 ? 'query' : 'queries'} " \
          "(#{sql_time_spent.duration})"
      end

      def prepare_props(store)
        store[:request].each_with_object({}) do |props, buffer|
          case props[:args][:scope]
          when :partial
            buffer[:partials] ||= []
            buffer[:partials] << view_log(
              path: props[:args][:path],
              duration: props[:duration]
            )
          when :layout, :view
            buffer[props[:args][:scope]] = view_log(
              path: props[:args][:path],
              duration: props[:duration]
            )
          else
            buffer.merge!(props[:args].except(:scope))
          end
        end
      end
    end
  end
end
