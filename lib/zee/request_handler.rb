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

      # Execute the action on the controller.
      controller.public_send(action_name)

      # If no status is set, then let's assume the action is implicitly
      # rendering the template.
      controller.render(action_name) unless response.status

      [response.status, response.headers.to_h, [response.body]]
    end
  end
end
