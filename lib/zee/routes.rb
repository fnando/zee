# frozen_string_literal: true

module Zee
  class Routes
    def initialize(&)
      @store = []
      instance_eval(&)
    end

    # Find a route that matches the current request.
    #
    # @param request [Zee::Request] the current request.
    def find(request)
      @store.find do |route|
        route.match?(request)
      end
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
    # @param constraints [Hash] the constraints to match.
    # @param defaults [Hash] the default values for the route.
    def match(path, via:, to:, as: nil, constraints: nil, defaults: nil)
      @store << Route.new(path:, via:, to:, as:, constraints:, defaults:)
    end
  end
end
