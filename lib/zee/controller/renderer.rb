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
      def render(
        template_name = action_name,
        status: :ok,
        layout: nil,
        **options
      )
        app = Zee.app

        raise DoubleRenderError if response.performed?

        return render_json(status, options.delete(:json)) if options.key?(:json)
        return render_text(status, options.delete(:text)) if options.key?(:text)

        mimes = possible_mime_types(template_name)
        found_view = find_template(template_name, mimes)
        found_layout = find_layout(layout, [found_view.mime]) if layout != false

        response.view = found_view
        response.layout = found_layout
        locals = collect_locals

        body = instrument(:request, scope: :view, path: found_view.path) do
          app.render_template(
            found_view.path,
            locals:,
            request:,
            controller: self,
            context: helpers
          )
        end

        if found_layout
          body =
            instrument(:request, scope: :layout, path: found_layout.path) do
              app.render_template(
                found_layout.path,
                locals:,
                request:,
                controller: self,
                context: helpers
              ) { SafeBuffer.new(body) }
            end
        end

        response.status(status)
        response.headers[:content_type] = found_view.mime.content_type
        response.body = body
      end

      # @api private
      private def render_text(status, text)
        response.status(status)
        response.headers[:content_type] = TEXT_PLAIN
        response.body = text.to_s
      end

      # @api private
      private def render_json(status, data)
        response.status(status)
        response.headers[:content_type] = APPLICATION_JSON
        response.body = Zee.app.config.json_serializer.dump(data)
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
      # @return [Template, nil]
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

              return Template.new(path: layout_path, mime:) if layout_path
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
        find_template("_#{name}", [response.view.mime])
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
      # @return [Template, nil]
      # @raise [MissingTemplateError]
      def find_template(name, mimes, required: true)
        name_ancestry.each do |controller_name|
          mimes.each do |mime|
            view_paths.each do |search_path|
              Zee.app.config.template_handlers.each do |handler|
                ext = [mime.extension, MIME_EXTENSION_ALIAS[mime.extension]]
                      .compact
                      .join(COMMA)

                view_path = search_path
                            .join(controller_name)
                            .glob("#{name}.{#{ext}}.#{handler}")
                            .first

                return Template.new(path: view_path, mime:) if view_path&.file?
              end
            end
          end
        end

        return unless required

        content_types = mimes.map(&:content_type)

        raise MissingTemplateError,
              "couldn't find template for #{controller_name}/#{name} " \
              "for #{content_types.inspect}"
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
        # `file.xml.erb` (the last extension component depends on the engines
        # that are enabled via {Zee::Config#template_handlers}).
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

        mimes << MiniMime.lookup_by_extension(HTML) if mimes.empty?

        mimes
      end
    end
  end
end
