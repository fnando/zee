# frozen_string_literal: true

module Zee
  class Route
    attr_reader :path, :via, :to, :as, :constraints, :defaults, :matcher

    def initialize(path:, via:, to:, as:, constraints:, defaults:)
      @path = normalize_slashes(path)
      @matcher = parse_path(@path)
      @via = Array(via).compact.map(&:to_sym)
      @to = to
      @as = as
      @constraints = constraints
      @defaults = defaults || {}
    end

    def match?(request)
      match_path?(request) && match_request_method?(request)
    end

    private def match_path?(request)
      request.path.match?(matcher)
    end

    private def match_request_method?(request)
      via.include?(request.request_method.downcase.to_sym)
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
