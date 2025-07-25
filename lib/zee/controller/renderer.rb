# frozen_string_literal: true

module Zee
  class Controller
    module Renderer
      include Instrumentation
      using Zee::Core::String
      using Zee::Core::Blank

      # @api private
      #
      # Define alias for mime extension, so we can have file.text.erb instead
      # of file.txt.erb.
      MIME_EXTENSION_ALIAS = {
        "txt" => "text"
      }.freeze

      # @api private
      CONTROLLERS_PREFIX = "controllers/"

      # @api private
      APPLICATION = "application"

      # @api private
      HTML_RENDERER = lambda do |response:, status:, object:, **|
        response.status(status)
        response.headers[:content_type] = TEXT_HTML
        response.body = response.body = if object.respond_to?(:to_html)
                                          object.to_html
                                        else
                                          object.to_s
                                        end
      end

      # @api private
      XML_RENDERER = lambda do |response:, status:, object:, **|
        response.status(status)
        response.headers[:content_type] = APPLICATION_XML
        response.body = if object.respond_to?(:to_xml)
                          object.to_xml
                        else
                          object.to_s
                        end
      end

      # @api private
      JSON_RENDERER = lambda do |response:, status:, object:, **|
        response.status(status)
        response.headers[:content_type] = APPLICATION_JSON
        response.body = Zee.app.config.json_serializer.dump(object)
      end

      # @api private
      TEXT_RENDERER = lambda do |response:, status:, object:, **|
        response.status(status)
        response.headers[:content_type] = TEXT_PLAIN
        response.body = object.to_s
      end

      # @api private
      BODY_RENDERER = lambda do |response:, status:, object:, options:|
        response.status(status)
        response.headers[:content_type] = options[:content_type] || TEXT_PLAIN
        response.body = object.to_s
      end

      # Render a template. The default is to render a template with the same
      # name as the action. The template must be named
      # `:name.:content_type.:template_handler`, as in `home.html.erb`.
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
      # @option options [Object] :html Render string as `text/html`.
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
      # @example Render a format.
      #   render text: "Hello"
      #   render html: "<h1>Hello</h1>"
      #   render json: {message: "Hello"}
      # @example Render a custom body.
      #   render body: "Hello"
      #   render body: "<svg></svg>", content_type: "image/svg+xml"
      def render(
        template_name = action_name,
        status: :ok,
        layout: nil,
        **options
      )
        raise DoubleRenderError if response.performed?

        options.each do |key, object|
          next unless Zee.app.config.format_renderers[key]

          Zee.app.config.format_renderers[key].call(
            response:,
            status:,
            object:,
            options: options.except(key)
          )
          return # rubocop:disable Lint/NonLocalExitFromIterator
        end

        if Rack::Utils.status_code(status) == 204
          return HTML_RENDERER.call(response:, status:, object: "")
        end

        mimes = possible_mime_types(template_name)
        found_view = find_template(template_name, mimes)
        found_layout = find_layout(layout, [found_view.mime]) if layout != false

        response.view = found_view
        response.layout = found_layout
        locals = collect_locals.merge(:@_controller => self)
        context = helpers.clone
                         .extend(ViewHelpers::Partial)

        body = instrument(:request, scope: :view, path: found_view.path) do
          Zee.app.render_template(
            found_view.path,
            locals:,
            request:,
            controller: self,
            context:
          )
        end

        if found_layout
          body =
            instrument(:request, scope: :layout, path: found_layout.path) do
              Zee.app.render_template(
                found_layout.path,
                locals:,
                request:,
                controller: self,
                context:
              ) { SafeBuffer.new(body) }
            end
        end

        response.status(status)
        response.headers[:content_type] = found_view.mime.content_type
        response.body = body
      end

      # @api private
      private def name_ancestry
        names =
          self
          .class
          .ancestors
          .filter_map do |klass|
            klass.is_a?(Class) &&
              klass < Zee::Controller &&
              klass.name.present? &&
              klass.name.underscore.delete_prefix(CONTROLLERS_PREFIX)
          end

        (names + [APPLICATION]).uniq
      end

      # @api private
      # Find possible layout names based on the controller ancestry.
      # The lookup will always stop at [Zee::Controller] and will use
      # `application` as the last fallback.
      def possible_layout_names(layout)
        [layout, *name_ancestry].compact.uniq
      end

      # @api private
      # Find a layout template file.
      #
      # @param name [String] The layout name.
      # @param mimes [Array<MiniMime::Info>] A list of possible mime types that
      #                                      will be used to search the
      #                                      template. Template files must
      #                                      follow the `name.:format.:engine`
      #                                      pattern.
      # @return [Template::Info, nil]
      # @raise [MissingTemplateError]
      def find_layout(name, mimes)
        mimes.each do |mime|
          view_paths.each do |view_path|
            possible_layout_names(name).each do |layout|
              ext = [mime.extension, MIME_EXTENSION_ALIAS[mime.extension]]
                    .compact
                    .join(COMMA)

              layout_path =
                view_path.glob("layouts/#{layout}.{#{ext}}.*").first

              return Template::Info.new(path: layout_path, mime:) if layout_path
            end
          end
        end

        nil
      end

      # @api private
      # Find a partial template.
      #
      # @param name [String] The partial name.
      # @raise [MissingTemplateError]
      # @return [Pathname]
      def find_partial(name)
        name = [File.dirname(name), "_#{File.basename(name)}"].join(SLASH)
        find_template(name, [response.view.mime])
      end

      # @api private
      # Find the template by name.
      # It considers the enabled engines and the view paths.
      #
      # @param name [String] The template name.
      # @param mimes [Array<MiniMime::Info>] A list of possible mime types that
      #                                      will be used to search the
      #                                      template. Template files must
      #                                      follow the `name.:format.:engine`
      #                                      pattern.
      # @param required [Boolean] When required, raises [MissingTemplateError]
      #                           if the template is not found.
      # @return [Template::Info, nil]
      # @raise [MissingTemplateError]
      def find_template(name, mimes, required: true)
        lookup_dirs = []

        mime_exts = mimes.map do |mime|
          [
            mime,
            [mime.extension, MIME_EXTENSION_ALIAS[mime.extension]]
              .compact
              .join(COMMA)
          ]
        end

        # First, try to find template based on ancestry.
        name_ancestry.each do |controller_name|
          mime_exts.each do |(mime, ext)|
            view_paths.each do |search_path|
              dir = search_path.join(controller_name)
              lookup_dirs << dir
              view_path = dir
                          .glob([
                            "#{name}.#{I18n.locale}.{#{ext}}.*",
                            "#{name}.{#{ext}}.*"
                          ])
                          .first

              if view_path&.file?
                return Template::Info.new(path: view_path, mime:)
              end
            end
          end
        end

        # Then, try to lookup for view_path + name.
        mime_exts.each do |(mime, ext)|
          view_paths.each do |search_path|
            lookup_dirs << search_path
            view_path = search_path
                        .glob("#{name}.{#{ext}}.*")
                        .first

            if view_path&.file?
              return Template::Info.new(path: view_path, mime:)
            end
          end
        end

        return unless required

        content_types = mimes.map(&:content_type)
        name = name.to_s.gsub("./", "")
        lookup_dirs =
          lookup_dirs
          .map {|dir| dir.relative_path_from(Zee.app.root) }
          .uniq
          .join(", ")

        raise MissingTemplateError,
              "couldn't find template #{name.inspect} " \
              "for #{content_types.inspect} (locale=#{I18n.locale}) " \
              "in #{lookup_dirs}"
      end

      # @api private
      def collect_locals
        instance_variables.each_with_object({}) do |name, buffer|
          buffer[name] = instance_variable_get(name)
        end
      end

      # @api private
      def possible_mime_types(template_name)
        accept = request.env[HTTP_ACCEPT].to_s.strip
        accept_all = accept == HTTP_ACCEPT_ALL || accept.blank?

        mimes = Rack::Utils
                .q_values(accept)
                .sort_by(&:last)
                .reverse
                .map { MiniMime.lookup_by_content_type(_1.first) }
                .compact

        # When `Accept: */*` is provided, we also need to find a template that
        # matches the extension. We're looking for files like `file.html.erb` or
        # `file.xml.erb`.
        if accept_all && mimes.empty?
          view_paths.each do |view_path|
            exts = view_path.glob("#{controller_name}/#{template_name}.*.*")
                            .map(&:basename)
            format = exts.to_s.split(DOT)[1]
            mime = MiniMime.lookup_by_extension(format) if format

            next unless mime

            mimes << mime
            break
          end
        end

        mimes << MiniMime.lookup_by_extension(Zee::HTML) if mimes.empty?

        mimes
      end
    end
  end
end
