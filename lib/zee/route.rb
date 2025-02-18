# frozen_string_literal: true

module Zee
  class Route
    # The path of the route.
    # @return [String]
    attr_reader :path

    # The HTTP methods of the route.
    # @return [Array<Symbol>] the HTTP methods.
    attr_reader :via

    # The destination of the route.
    # @return [String]
    attr_reader :to

    # The name of the route. When set, URL helpers are defined.
    # @return [Symbol]
    # @see {#helpers}
    attr_reader :name

    # The constraints of the route.
    # @return [Array<Hash, Proc>]
    attr_reader :constraints

    # The default values of the route.
    # @return [Hash]
    attr_reader :defaults

    def initialize(path:, via:, to:, name:, constraints:, defaults:)
      @path = normalize_slashes(path)
      @via = Array(via).compact.map(&:to_sym)
      @to = to
      @name = name
      @constraints = Array(constraints).flatten.compact
      @defaults = defaults || {}
    end

    def match?(request)
      return false unless match_path?(request)

      params = request.path_with_no_trailing_slash
                      .match(parser.matcher)
                      .named_captures
                      .each_with_object({}) do |(key, value), hash|
                        key = key.to_sym
                        hash[key] = value || defaults[key]
                      end
      request.params.merge!(params)

      match_request_method?(request) &&
        match_constraints?(request)
    end

    # The parser for the route.
    # @return [Parser]
    def parser
      @parser ||= Parser.new(path)
    end

    private def match_path?(request)
      request.path_with_no_trailing_slash.match?(parser.matcher)
    end

    private def match_request_method?(request)
      via.include?(request.request_method.downcase.to_sym)
    end

    private def match_constraints?(request)
      return true if constraints.empty?

      hash =
        constraints
        .select { _1.is_a?(Hash) }
        .each_with_object({}) {|constraint, buffer| buffer.merge!(constraint) }

      callable = constraints.select do |constraint|
        constraint.respond_to?(:call) || constraint.respond_to?(:match?)
      end

      match_hash_constraints?(request, hash) &&
      match_callable_constraints?(request, callable)
    end

    private def match_hash_constraints?(request, constraints)
      constraints.all? do |key, constraint|
        if parser.segments.key?(key)
          constraint === request.params[key] # rubocop:disable Style/CaseEquality
        elsif request.respond_to?(key)
          constraint === request.public_send(key) # rubocop:disable Style/CaseEquality
        end
      end
    end

    private def match_callable_constraints?(request, constraints)
      constraints.all? do |constraint|
        if constraint.respond_to?(:call)
          constraint.call(request)
        else
          constraint.match?(request)
        end
      end
    end

    private def normalize_slashes(path)
      path = "/#{path}" unless path.start_with?("(")
      path.squeeze("/")
    end
  end
end
