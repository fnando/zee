# frozen_string_literal: true

module Zee
  # Raised when a template is missing.
  MissingTemplateError = Class.new(StandardError)

  class Controller
    attr_reader :request, :response, :action_name, :controller_name

    def initialize(request:, response:, action_name: nil, controller_name: nil)
      @request = request
      @response = response
      @action_name = action_name
      @controller_name = controller_name
    end

    # Render a template. The default is to render a template with the same name
    # as the action. The template must be
    # named `:name.:content_type.:template_handler`, as in `home.html.erb`.
    #
    # @param template_name [String] The name of the template to render.
    #                               Defaults to the action name.
    # @param status [Integer|Symbol] The status code of the response.
    #                                Defaults to `:ok`.
    # @example
    # ```ruby
    # render
    # render :home
    # render :show, status: :created
    # ```
    def render(template_name = action_name, status: :ok)
      accept = request.env[HTTP_ACCEPT] || TEXT_HTML
      mimes = Rack::Utils
              .q_values(accept)
              .sort_by(&:last)
              .reverse
              .map { MiniMime.lookup_by_content_type(_1.first) }
              .compact

      root = request.env[RACK_ZEE_APP].root
      base = root.join("app/views/#{controller_name}/#{template_name}")

      # TODO: make template handlers configurable
      handlers = %w[erb]

      # Get a list of files like `app/views/pages/home.html.erb`.
      template_paths = build_template_paths(mimes, handlers, base)

      # Find the first file that exists.
      mime, template_path = *template_paths.find {|(_, path)| File.file?(path) }

      unless template_path
        list = template_paths
               .map {|(_, path)| path.relative_path_from(root) }
               .join(", ")
        raise MissingTemplateError,
              "#{controller_name}##{template_name}: #{list}"
      end

      response.status(status)
      response.headers[:content_type] = mime&.content_type
      response.body = Tilt.new(template_path).render
    end

    private def build_template_paths(mimes, template_handlers, base_path)
      list = mimes.map do |content_type|
        template_handlers.map do |handler|
          [
            content_type,
            Pathname("#{base_path}.#{content_type.extension}.#{handler}")
          ]
        end
      end

      list.first
    end
  end
end
