# frozen_string_literal: true

module Zee
  module Renderer
    # Render a template. The default is to render a template with the same name
    # as the action. The template must be
    # named `:name.:content_type.:template_handler`, as in `home.html.erb`.
    #
    # @param template_name [String] The name of the template to render.
    #                               Defaults to the action name.
    # @param status [Integer, Symbol] The status code of the response.
    #                                 Defaults to `:ok`.
    # @param layout [String] The layout to use for the template. When `nil`,
    #                        the default layout is used (first a layout file
    #                        matching the controller, then application).
    #                        To skip a layout file entirely,
    #                        use `layout: false`.
    # @param options [Hash] Additional options.
    # @option options [Object] :json Render object as `application/json`.
    # @option options [Object] :text Render string as `text/plain`.
    #
    # @example Implicit render uses the action name as the template name.
    #   render
    # @example Explicit render.
    #   render :home
    # @example Render with a different status.
    #   render :show, status: :created
    # @example Render without a layout.
    #   render :home, layout: false
    # @example Render with a custom layout.
    #   render :home, layout: :custom
    def render(template_name = action_name, status: :ok, layout: nil, **options)
      app = request.env[RACK_ZEE_APP]

      return render_json(status, options.delete(:json)) if options.key?(:json)
      return render_text(status, options.delete(:text)) if options.key?(:text)

      accept = (request.env[HTTP_ACCEPT] || TEXT_HTML).to_s.strip
      mimes = Rack::Utils
              .q_values(accept)
              .sort_by(&:last)
              .reverse
              .map { MiniMime.lookup_by_content_type(_1.first) }
              .compact

      if accept == HTTP_ACCEPT_ALL || accept.empty?
        # Try to find all possible mimes based on templates that exist.
        mimes = app.root
                   .glob("app/views/#{controller_name}/#{template_name}.*.*")
                   .flat_map { _1.basename.to_s.split(DOT)[1] }
                   .map { MiniMime.lookup_by_extension(_1) }

        # If no mimes are found, then default to HTML.
        mimes = [MiniMime.lookup_by_extension(HTML)] if mimes.empty?
      end

      root = app.root
      view_base = root.join("app/views/#{controller_name}/#{template_name}")
      layout_bases = [
        (root.join("app/views/layouts/#{layout}") if layout),
        root.join("app/views/layouts/#{controller_name}"),
        root.join("app/views/layouts/application")
      ].compact

      # Get a list of files like `app/views/pages/home.html.erb`.
      view_paths = build_template_paths(
        mimes,
        app.config.template_handlers,
        view_base
      )

      # Get a list of files like `app/views/layouts/application.html.erb`.
      layout_paths = layout_bases.flat_map do |layout_base|
        build_template_paths(
          mimes,
          app.config.template_handlers,
          layout_base
        )
      end

      # Find the first file that exists.
      view_path = view_paths.find {|tp| File.file?(tp[:path]) }
      layout_path = layout_paths.find {|tp| File.file?(tp[:path]) }

      unless view_path
        list = view_paths
               .map { _1[:path].relative_path_from(root) }
               .join(", ")

        raise Controller::MissingTemplateError,
              "#{controller_name}##{template_name}: #{list}"
      end

      body = app.render_template(view_path[:path], locals:)

      if layout != false && layout_path
        body = app.render_template(layout_path[:path], locals:) do
          SafeBuffer.new(body)
        end
      end

      response.status(status)
      response.headers[:content_type] = view_path[:mime]&.content_type
      response.body = body
    end

    private def build_template_paths(mimes, template_handlers, base_path)
      mimes.flat_map do |mime|
        template_handlers.map do |handler|
          {
            mime:,
            path: Pathname("#{base_path}.#{mime.extension}.#{handler}")
          }
        end
      end
    end

    private def render_text(status, text)
      response.status(status)
      response.headers[:content_type] = TEXT_PLAIN
      response.body = text.to_s
    end

    private def render_json(status, data)
      response.status(status)
      response.headers[:content_type] = APPLICATION_JSON
      response.body = request.env[RACK_ZEE_APP]
                             .config
                             .json_serializer
                             .dump(data)
    end
  end
end
