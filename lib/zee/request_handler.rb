# frozen_string_literal: true

module Zee
  # @api private
  class RequestHandler
    include Instrumentation

    # @return [Zee::Application] the application.
    attr_reader :app

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Request.new(env)
      response = Response.new
      route = app.routes.find(request)

      unless route
        instrument :request, status: 404
        return [404, {HTTP_CONTENT_TYPE => TEXT_PLAIN}, [NOT_FOUND]]
      end

      # If the route is a rack app, route to it.
      return route_to_app(env, route) if route.to.respond_to?(:call)

      instrument :request, scope: :route, name: route.to

      controller_name, action_name = *route.to.split(POUND_SIGN)

      expected_const =
        app
        .loader
        .cpath_expected_at("app/controllers/#{controller_name}.rb")

      controller_class = Object.const_get(expected_const)

      controller = controller_class.new(
        request:,
        response:,
        action_name:,
        controller_name:
      )

      controller.extend(app.routes.helpers)
      controller.send(:call)

      content_type = response.headers[:content_type]

      # TODO: move this to a middleware.
      unless content_type&.include?(CHARSET)
        charset = Encoding.default_external.name
        content_type = "#{content_type}; charset=#{charset}"
        response.headers[:content_type] = content_type
      end

      [response.status, response.headers.to_h, [response.body]]
    end

    # @api private
    # This will route the request to the rack app.
    # We use [Rack::URLMap](https://www.rubydoc.info/gems/rack/Rack/URLMap),
    # because it handles the `SCRIPT_NAME` and `PATH_INFO` for us.
    #
    # @param env [Hash] the environment hash.
    # @param route [Zee::Route] the route to route to.
    # @return [Array] the rack response.
    private def route_to_app(env, route)
      instrument :request, run_rack_app: route.to do
        ::Rack::URLMap.new(route.path => route.to).call(env)
      end
    end
  end
end
