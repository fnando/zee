# frozen_string_literal: true

module Zee
  module CLI
    class Root < Command
      module Routes
        class JavaScript
          using Core::String
          using Core::Blank

          Route = Data.define(
            :path,
            :name,
            :method_name,
            :args,
            :required_names,
            :all_names,
            :components
          )

          def initialize(routes)
            @routes = routes.select(&:name).map { build_route(_1) }
          end

          def build_route(route)
            components = route.parser.components[1..-1] || []
            components = components.map do |component|
              if component.start_with?(":")
                component[1..-1].to_s.camelize(:lower)
              else
                component.inspect
              end
            end

            all_names = []
            required_names = []
            segments = route.parser.segments

            args = segments.each_with_object([]) do |(key, segment), buffer|
              name = key.to_s.camelize(:lower)
              arg = name
              required_names << name unless segment.optional?
              all_names << name
              buffer << arg
            end

            type = []
            type << "{ #{args.join('; ')} }" if args.any?

            Route.new(
              name: route.name,
              method_name: "#{route.name.to_s.camelize(:lower)}URL",
              path: route.path,
              args: "args",
              required_names:,
              all_names:,
              components:
            )
          end

          def render
            ERB
              .new(
                File.read(File.join(__dir__, "javascript.erb")),
                trim_mode: "<>-"
              )
              .result(binding)
          end
        end
      end
    end
  end
end
