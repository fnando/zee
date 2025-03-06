# frozen_string_literal: true

module Zee
  class Routes
    # The default URL options for the routes.
    # @return [Hash]
    attr_accessor :default_url_options

    def initialize(default_url_options = {}, &)
      @default_url_options = default_url_options
      @store = []
      @defaults = []
      @constraints = []
      instance_eval(&) if block_given?
    end

    # Get all routes in array form.
    # @return [Array<Zee::Route>]
    def to_a
      @store.dup
    end

    # Find a route by its name.
    # @param name [String] the name of the route.
    # @return [Zee::Route, nil] the route that matches the name.
    #
    # @example
    #   routes = Zee::Routes.new do
    #     get "posts/:id", to: "posts#show", as: :post
    #   end
    #
    #   routes.find_by_name(:post).name
    #   #=> :post
    def find_by_name(name)
      @store.find { _1.name == name }
    end

    # Define a route helper module.
    # For each named route, a method `_path` and `_url` is defined.
    # The `_path` method returns the path for the route, while the `_url` method
    # returns the full URL.
    #
    # @return [Module]
    #
    # @example
    #   routes = Zee::Routes.new do
    #     root to: "home#index"
    #     get "posts/:id", to: "posts#show", as: :post
    #   end
    #
    #   routes.default_url_options = {host: "example.com", protocol: "https"}
    #
    #   helpers = Object.new.extend(routes.helpers)
    #
    #   helpers.root_path
    #   #=> "/"
    #
    #   helpers.post_path(1)
    #   #=> "/posts/1"
    #
    #   helpers.post_url(1)
    #   #=> "https://example.com/posts/1"
    def helpers
      @helpers ||= begin
        routes = self
        store = @store

        Module.new do
          define_method :routes do
            routes
          end

          def default_url_options
            routes.default_url_options
          end

          store.each do |route|
            next unless route.name

            args = []
            names = []

            route.parser.segments.each_value do |segment|
              args << if segment.optional?
                        "#{segment.name} = nil"
                      else
                        segment.name
                      end
              names << segment.name
            end

            args_path = [*args, "**"].join(", ")
            args_url = [*args, "host: nil, protocol: nil, **"].join(", ")
            names = names.join(", ")
            call = [route.name.inspect, names, "**"].reject(&:empty?).join(", ")

            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{route.name}_path(#{args_path})
                url_for(#{call})
              end

              def #{route.name}_url(#{args_url})
                host = host || default_url_options[:host]
                protocol = protocol || default_url_options[:protocol]

                unless host
                  raise ArgumentError, "Please provide the :host parameter, " \
                                       "set default_url_options[:host]"
                end

                url_for(#{call}, protocol:, host:, **)
              end
            RUBY
          end

          # @return [String] Full URL for the route
          # @param host [String] The host to use. If not provided,
          #                      `default_url_options` will be used instead.
          # @param protocol [String] The protocol to use.
          # @param anchor [String] The anchor to use.
          # @param kwargs [Hash] The query parameters.
          # @param [Object] name
          # @param [Array<Object>] args
          def url_for(
            name,
            *args,
            host: nil,
            protocol: nil,
            anchor: nil,
            **kwargs
          )
            route = routes.find_by_name(name)
            path = route.parser.build_path(*args)
            query = Rack::Utils.build_nested_query(kwargs) if kwargs.any?

            suffix = query ? "#{path}?#{query}" : path
            protocol = "#{protocol}:" if protocol
            url = "#{protocol}//#{host}" if host
            url = "#{url}#{suffix}"
            url = "#{url}##{anchor}" if anchor

            url
          end
        end
      end
    end

    # Find a route that matches the current request.
    #
    # @param request [Zee::Request] the current request.
    # @return [Zee::Route, nil] the route that matches the request.
    def find(request)
      @store.find { _1.match?(request) }
    end

    # Mount a Rack app at a specific path.
    #
    # The mounting path does not support dynamic segments as regular routes.
    # That means routes like `/posts/:id` are not supported.
    #
    # > [!NOTE]
    # > The Rack app won't inherit any middleware. In that case, you
    # > can wrap the app with something like
    # > [`Rack::Builder.app(&block)`](https://www.rubydoc.info/gems/rack/Rack/Builder)
    # > and include the middleware you care about.
    #
    # @param app [#call] the Rack app to mount.
    # @param at [String] the path to mount the Rack app.
    # @param as [String] the name of the route.
    # @param via [Array(Symbol)] the HTTP method(s) to match.
    def mount(app, at:, as: nil, via: :all)
      unless app.respond_to?(:call)
        raise ArgumentError,
              "A rack application must be specified; got #{app.inspect}"
      end

      match(at, via:, as:, to: app)
    end

    # Define root route, like `GET /`.
    # See {#match} for more information.
    def root(to:, as: :root)
      get(SLASH, to:, as:)
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

    # Define DELETE route.
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

    # Define an app route.
    #
    # @param path [String] the path to match.
    # @param via [Array(Symbol)] the HTTP method(s) to match.
    # @param to [String, #call] the controller and action to route to,
    #                           like `posts#show`. You can also provide any
    #                           object that responds to `#call`.
    # @param as [String] the name of the route.
    # @param constraints [Hash, #match?, #call] the constraints to match.
    #                                           See {#constraints}.
    # @param defaults [Hash] the default values for the route. See {#defaults}.
    def match(path, via:, to:, as: nil, constraints: nil, defaults: nil)
      defaults = merge_hash(@defaults, defaults)
      constraints = (@constraints + [constraints]).flatten.compact

      @store << Route.new(path:, via:, to:, name: as, constraints:, defaults:)
    end

    # Define the default value for optional segments.
    # This method can be nested to define different default values for different
    # segments.
    #
    # @param defaults [Hash] the default values for the route.
    # @example
    #   defaults(locale: "en") do
    #     get "(/:locale)/posts/:id", to: "posts#show"
    #   end
    def defaults(defaults = nil, &)
      @defaults << defaults if defaults
      yield
    ensure
      @defaults.pop if defaults
    end

    # Define a subdomain constraint.
    #
    # @param subdomain [String, Regexp] the subdomain that should be matched.
    # @example
    #   subdomain("api") do
    #     get "posts/:id", to: "posts#show"
    #   end
    def subdomain(subdomain, &)
      constraints(subdomain:, &)
    end

    # Define constraints for the route.
    # This method can be nested to define different constraints for different
    # segments.
    #
    # @param constraints [Hash, #call] the constraints to match.
    # @example
    #   constraints locale: /^en|pt-BR$/ do
    #     get "(/:locale)/posts/:id", to: "posts#show"
    #   end
    def constraints(constraints = nil, &)
      @constraints << constraints if constraints
      yield
    ensure
      @constraints.pop if constraints
    end

    # @api private
    private def merge_hash(list, other)
      list.push(other)
          .flatten
          .compact
          .each_with_object({}) {|entry, buffer| buffer.merge!(entry) }
    end
  end
end
