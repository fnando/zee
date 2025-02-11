module Zee
  class Route
    attr_reader :path, :via, :to, :as, :constraints, :defaults, :matcher

    def initialize(path:, via:, to:, as:, constraints:, defaults:)
      @path = normalize_slashes(path)
      @matcher = parse_path(@path)
      @via = Array(via).compact.map(&:to_sym)
      @to = to
      @as = as
      @constraints = Array(constraints).flatten.compact
      @defaults = defaults || {}
    end

    def match?(request)
      return false unless match_path?(request)

      params = request.path_with_no_trailing_slash
                      .match(matcher)
                      .named_captures
                      .each_with_object({}) do |(key, value), hash|
                        key = key.to_sym
                        hash[key] = value || defaults[key]
                      end
      request.params.merge!(params)

      match_request_method?(request) &&
        match_constraints?(request)
    end

    def segments
      @segments ||= path.scan(/:(\w+)/).flatten.map(&:to_sym)
    end

    private def match_path?(request)
      request.path_with_no_trailing_slash.match?(matcher)
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
        if segments.include?(key)
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

    private def parse_path(path)
      path = path
             .gsub(/\((.*?)\)/, "(?:\\1)?")
             .gsub(/:(\w+)/, "(?<\\1>[^/]+)")
      Regexp.new("^#{path}$")
    end
  end
end
