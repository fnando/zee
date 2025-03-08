# frozen_string_literal: true

module Zee
  class Route
    class Parser
      # The pattern to match against.
      # @return [String] the pattern.
      attr_reader :pattern

      def initialize(pattern)
        @pattern = pattern
      end

      # The segments of the pattern.
      # @return [Array<Segment>] the segments.
      # @example
      #  parser = Zee::Route::Parser.new("/posts/:id")
      #  parser.segments
      #  #=> [#<struct Zee::Route::Segment name=:id, optional?=false>]
      def segments
        @segments ||= begin
          result =
            pattern
            .scan(/:(\w+)/)
            .flatten
            .each_with_object({}) {|name, buffer| buffer[name] = false }

          result =
            pattern
            .scan(%r{\(/:(.*?)\)})
            .flatten
            .each_with_object(result) {|name, buffer| buffer[name] = true }

          result.each_with_object({}) do |(key, value), buffer|
            key = key.to_sym
            buffer[key] = Segment.new(key, value)
          end
        end
      end

      # The matcher for the pattern.
      # @return [Regexp] the matcher.
      def matcher
        @matcher ||= if pattern == SLASH
                       %r{^/$}
                     else
                       regex = pattern
                               .gsub(%r{\(/:(.*?)\)}, "(/(?<\\1>[^/]+))?")
                               .gsub(/(?::(\w+))/, "(?<\\1>[^/]+)")
                               .gsub(SLASH, "\\/")

                       Regexp.new("^#{regex}$")
                     end
      end

      def components
        @components ||= pattern.gsub(/[()]/, EMPTY_STRING).split(SLASH)
      end

      def to_param(value)
        return value.to_param if value.respond_to?(:to_param)
        return value.id if value.respond_to?(:id)

        primitive = value.nil? ||
                    value.is_a?(String) ||
                    value.is_a?(Symbol) ||
                    value.is_a?(Integer)

        return value.to_s if primitive

        raise ArgumentError,
              "Cannot convert #{value.inspect} to param; implement either " \
              "#to_param or #id, or pass a string"
      end

      def build_path(*args)
        return "/" if components.empty?
        return pattern if segments.empty?

        params = segments.keys.zip(args).to_h
        path = []

        components.each do |component|
          if component.start_with?(":")
            name = component[1..-1].to_sym
            value = to_param(params[name]).to_s

            next if segments[name].optional? && value.empty?

            if !segments[name].optional? && value.empty?
              raise ArgumentError,
                    "#{name.inspect} is required for #{pattern}"
            end

            path << value
          else
            path << component
          end
        end

        path.join("/")
      end
    end
  end
end
