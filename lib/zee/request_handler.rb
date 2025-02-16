# frozen_string_literal: true

module Zee
  # @private
  class RequestHandler
    attr_reader :app

    def initialize(app)
      @app = app
    end

    def call(env)
      request = Request.new(env)
      response = Response.new
      route = app.routes.find(request)

      unless route
        return [404, {"content-type" => "text/plain"}, ["404 Not Found"]]
      end

      controller_name, action_name = *route.to.split("#")

      controller_class = Object.const_get(
        app
         .loader
         .cpath_expected_at("app/controllers/#{controller_name}.rb")
      )
      controller = controller_class.new(
        request:,
        response:,
        action_name:,
        controller_name:
      )

      controller.send(:call)

      content_type = response.headers[:content_type]

      # TODO: move this to a middleware.
      unless content_type&.include?("charset")
        charset = Encoding.default_external.name
        content_type = "#{content_type}; charset=#{charset}"
        response.headers[:content_type] = content_type
      end

      [response.status, response.headers.to_h, [response.body]]
    end
  end
end
