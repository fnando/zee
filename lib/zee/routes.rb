# frozen_string_literal: true

module Zee
  class Routes
    # The app config.
    # @return [Config]
    attr_reader :config

    def initialize(config = nil, &)
      @config = config
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
            routes.config&.default_url_options || {}
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

            args = [*args, DOUBLE_STAR_OPTIONS].join(COMMA_SPACE)
            names = names.join(COMMA_SPACE)
            call = [route.name.inspect, names, DOUBLE_STAR_OPTIONS]
                   .reject(&:empty?)
                   .join(COMMA_SPACE)

            class_eval <<~RUBY, __FILE__, __LINE__ + 1
              def #{route.name}_path(#{args})
                url_for(#{call})
              end

              def #{route.name}_url(#{args})
                options = default_url_options.merge(options)

                unless options[:host]
                  raise ArgumentError, "Please provide the :host parameter, " \
                                       "set default_url_options[:host]"
                end

                url_for(#{call}, **options)
              end
            RUBY
          end

          # @return [String] Full URL for the route
          # @param host [String] The host to use. If not provided,
          #                      `default_url_options` will be used instead.
          # @param protocol [String] The protocol to use.
          # @param anchor [String] The anchor to use.
          # @param kwargs [Hash] The query parameters.
          # @param port [Integer, nil]
          # @param args [Array<Object>]
          # @param name [Symbol]
          def url_for(
            name,
            *args,
            host: nil,
            port: nil,
            protocol: nil,
            anchor: nil,
            **kwargs
          )
            route = routes.find_by_name(name)
            path = route.parser.build_path(*args)
            query = Rack::Utils.build_nested_query(kwargs) if kwargs.any?

            uri = URI.parse(SLASH)
            uri.scheme = protocol.to_s if protocol
            uri.host = host if host
            uri.port = port if port
            uri.path = path
            uri.query = query if query
            uri.fragment = anchor if anchor

            uri.to_s
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
    #
    # @example Mouting a Rack app
    #   mount Sidekiq::Web, at: "sidekiq"
    #   mount Sidekiq::Web, at: "sidekiq", as: :sidekiq
    def mount(app, at:, as: nil, via: :all)
      unless app.respond_to?(:call)
        raise ArgumentError,
              "A rack application must be specified; got #{app.inspect}"
      end

      match(at, via:, as:, to: app)
    end

    # Redirect a path to another path.
    # This method is useful to redirect old paths to new paths.
    #
    # @param path [String] the path to match.
    # @param to [String] the path to redirect to.
    # @param status [Integer, Symbol] the HTTP status code to use. Defaults
    #                                 to `301 Moved Permanently`.
    #
    # @example
    #   redirect "old", to: "/"
    #   redirect "found", to: "/", status: :found
    #   redirect "found", to: "/", status: 302
    #   redirect "found", to: ->(env){[302, {"location"=>"/"}, []]}
    def redirect(path, to:, status: 301)
      app = if to.respond_to?(:call)
              to
            else
              Redirect.new(to.to_s, Rack::Utils.status_code(status))
            end

      match(path, via: :all, to: app)
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
    # ## Catch-all routes
    #
    # > [!WARNING]
    # > The catch-all placeholder must be used as the last segment of the route.
    # > Adding to the middle won't work at all.
    #
    # Catch-all routes allows to match any path. This is useful when you need
    # to handle generic/complex routes, rather than using the default parser.
    #
    #
    # > [!NOTE]
    # > When using catch-all routes, be aware that the route may prevent other
    # > routes from being rendered, due to the precedence. A good call is to
    # > always keep catch-all routes at the bottom of the route definition.
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
    #
    # @example Defining routes
    #   get "posts", to: "posts#index", as: :posts
    #   get "posts/:id", to: "posts#show", as: :post
    #   get "posts/:id/edit", to: "posts#edit", as: :edit_post
    #   post "posts/:id/edit", to: "posts#update"
    #
    # @example Defining catch-all routes
    #   get "*path", to: "catch_all#show"
    #   get "posts/:id/*path", to: "catch_all#show"
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
