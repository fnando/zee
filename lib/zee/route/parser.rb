# frozen_string_literal: true

module Zee
  class Route
    Segment = Struct.new(:name, :optional?) do
      def inspect
        "#<#{self.class.name} name=#{name.inspect} " \
          "optional=#{optional?.inspect}>"
      end
    end

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
        @matcher ||= if pattern == "/"
                       %r{^/$}
                     else
                       regex = pattern
                               .gsub(%r{\(/:(.*?)\)}, "(/(?<\\1>[^/]+))?")
                               .gsub(/(?::(\w+))/, "(?<\\1>[^/]+)")
                               .gsub("/", "\\/")

                       Regexp.new("^#{regex}$")
                     end
      end

      def components
        @components ||= pattern.gsub(/[()]/, "").split("/")
      end

      def build_path(*args)
        return "/" if components.empty?
        return pattern if segments.empty?

        params = segments.keys.zip(args).to_h
        path = []

        components.each do |component|
          if component.start_with?(":")
            name = component[1..-1].to_sym
            value = params[name].to_s

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
