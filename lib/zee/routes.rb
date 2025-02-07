# frozen_string_literal: true

module Zee
  class Routes
    def initialize(&)
      @store = []
      @defaults = []
      @constraints = []
      instance_eval(&) if block_given?
    end

    # Find a route that matches the current request.
    #
    # @param request [Zee::Request] the current request.
    def find(request)
      @store.find { _1.match?(request) }
    end

    # Define root route, like `GET /`.
    # See {#match} for more information.
    def root(to:, as: :root)
      get("/", to:, as:)
    end

    # Define GET route.
    # See {#match} for more information.
    def get(path, to:, as: nil, constraints: nil, defaults: nil)
      match(path, via: [:get], to:, as:, constraints:, defaults:)
    end

    # Define POST route.
    # See {#match} for more information.
    def post(path, to:, as: nil, constraints: nil, defaults: nil)
      match(path, via: [:post], to:, as:, constraints:, defaults:)
    end

    # Define PATCH route.
    # See {#match} for more information.
    def patch(path, to:, as: nil, constraints: nil, defaults: nil)
      match(path, via: [:patch], to:, as:, constraints:, defaults:)
    end

    # Define PUT route.
    # See {#match} for more information.
    def put(path, to:, as: nil, constraints: nil, defaults: nil)
      match(path, via: [:put], to:, as:, constraints:, defaults:)
    end

    # Define PUT route.
    # See {#match} for more information.
    def delete(path, to:, as: nil, constraints: nil, defaults: nil)
      match(path, via: [:delete], to:, as:, constraints:, defaults:)
    end

    # Define OPTIONS route.
    # See {#match} for more information.
    def options(path, to:, as: nil, constraints: nil, defaults: nil)
      match(path, via: [:options], to:, as:, constraints:, defaults:)
    end

    # Define HEAD route.
    # See {#match} for more information.
    def head(path, to:, as: nil, constraints: nil, defaults: nil)
      match(path, via: [:head], to:, as:, constraints:, defaults:)
    end

    # Definen app route.
    #
    # @param path [String] the path to match.
    # @param via [Array(Symbol)] the HTTP method(s) to match.
    # @param to [String|Callable] the controller and action to route to or an
    #                             object that responds to `#call()`.
    # @param as [String] the name of the route.
    # @param constraints [Hash] the constraints to match. See {#constraints}.
    # @param defaults [Hash] the default values for the route. See {#defaults}.
    def match(path, via:, to:, as: nil, constraints: nil, defaults: nil)
      defaults = merge_hash(@defaults, defaults)
      constraints = (@constraints + [constraints]).flatten.compact

      @store << Route.new(path:, via:, to:, as:, constraints:, defaults:)
    end

    # Define the default value for optional segments.
    # This method can be nested to define different default values for different
    # segments.
    #
    # @param defaults [Hash] the default values for the route.
    # @example
    # ```ruby
    #  defaults(locale: "en") do
    #    get "(/:locale)/posts/:id", to: "posts#show"
    #  end
    #  ```
    def defaults(defaults = nil, &)
      @defaults << defaults if defaults
      yield
    ensure
      @defaults.pop if defaults
    end

    # Define a subdomain constraint.
    #
    # @param subdomain [String|Regexp] the subdomain that should be matched.
    # @example
    # ```ruby
    #  subdomain("api") do
    #    get "posts/:id", to: "posts#show"
    #  end
    #  ```
    def subdomain(subdomain, &)
      constraints(subdomain:, &)
    end

    # Define constraints for the route.
    # This method can be nested to define different constraints for different
    # segments.
    #
    # @param constraints [Hash|Callable] the constraints to match.
    # @example
    # ```ruby
    #  constraints locale: /^en|pt-BR$/ do
    #    get "(/:locale)/posts/:id", to: "posts#show"
    #  end
    #  ```
    def constraints(constraints = nil, &)
      @constraints << constraints if constraints
      yield
    ensure
      @constraints.pop if constraints
    end

    private def merge_hash(list, other)
      list.push(other)
          .flatten
          .compact
          .each_with_object({}) {|entry, buffer| buffer.merge!(entry) }
    end
  end
end
