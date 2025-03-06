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
    # @see #helpers
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
      @app = to.respond_to?(:call)
    end

    # Whether the route is a rack app.
    # @return [Boolean]
    def app?
      @app
    end

    # Whether the route matches the request.
    # @param request [Request] the request.
    # @return [Boolean]
    def match?(request)
      return true if app? && match_app?(request)
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

    # Whether the route matches the request path for a rack app.
    # @param request [Request] the request.
    # @return [Boolean]
    private def match_app?(request)
      request.path_with_no_trailing_slash == path ||
      request.path_with_no_trailing_slash.start_with?("#{path}/")
    end

    # Whether the route matches the request path.
    # @param request [Request] the request.
    # @return [Boolean]
    private def match_path?(request)
      request.path_with_no_trailing_slash.match?(parser.matcher)
    end

    # Whether the route matches the request method.
    # @param request [Request] the request.
    # @return [Boolean]
    private def match_request_method?(request)
      via.include?(:all) || via.include?(request.request_method.downcase.to_sym)
    end

    # Whether the route matches the request constraints.
    # @param request [Request] the request.
    # @return [Boolean]
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

    # Whether the request matches the hash constraints.
    # The hash constraints will be matched first against segments and then
    # against the request object.
    # @param request [Request] the request.
    # @param constraints [Hash] the constraints.
    # @return [Boolean]
    private def match_hash_constraints?(request, constraints)
      constraints.all? do |key, constraint|
        if parser.segments.key?(key)
          constraint === request.params[key] # rubocop:disable Style/CaseEquality
        elsif request.respond_to?(key)
          constraint === request.public_send(key) # rubocop:disable Style/CaseEquality
        end
      end
    end

    # Whether the request matches the callable constraints.
    # If a constraint responds to #call or #match?, it will be called with the
    # request object.
    # @param request [Request] the request.
    # @param constraints [Array<#call, #match?>] the constraints.
    private def match_callable_constraints?(request, constraints)
      constraints.all? do |constraint|
        if constraint.respond_to?(:call)
          constraint.call(request)
        else
          constraint.match?(request)
        end
      end
    end

    # Normalize the slashes in the path.
    # @param path [String] the path.
    # @return [String]
    private def normalize_slashes(path)
      path = "/#{path}" unless path.start_with?(OPEN_PAREN)
      path.squeeze(SLASH)
    end
  end
end
