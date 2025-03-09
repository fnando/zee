# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Partial
      # ## Partial lookup
      #
      # When rendering a partial, for instance, `<%= render "header" %>`, Zee
      # will look for the partial in the following locations:
      #
      # 1. In the same directory as the current controller
      #    (e.g. `app/views/comments`).
      # 2. In the same directory as the current controller's parent directory
      #    (e.g. `app/views/application`).
      #
      # If no partial is found, Zee will raise a
      # {Controller::MissingTemplateError}.
      #
      # @example Rendering partial
      #   ```erb
      #   <%= render "header" %>
      #   ```
      #
      # @example Rendering partial with a collection
      #   ```erb
      #   <%= render "comment", comments, as: :comment %>
      #   ```
      #
      # @example Rendering partial with a collection using spacers
      #   ```erb
      #   <%= render "comment",
      #       comments, as: :comment,
      #       spacer: "comment_spacer" %>
      #   ```
      #
      # @example Rendering partial with locals
      #   ```erb
      #   <%= render "header", locals: {title: "MySite"} %>
      #   ```
      #
      # @example Rendering partial with object
      #    ```erb
      #    <%= render "comment", comment, as: :comment %>
      #    ```
      #
      # @example Rendering default case for collection
      #   The following example will render `no_comments` when the `comments`
      #   collection is empty.
      #
      #   ```erb
      #   <%= render "comment", comments, as: :comment, blank: "no_comments" %>
      #   ```
      #
      # @param name [String] The name of the partial to render.
      # @param object [Object] The object to render. When rendering a
      #                        collection (any object that responds to `#each`),
      #                        you can define the local variable name with the
      #                        `as` option.
      # @param as [Object, nil] The local variable name to use when rendering a
      #                         collection. Defaults to `:item`.
      # @param locals [Hash] Additional local variables to pass to the partial.
      # @param spacer [String, nil] A partial to render between each item in a
      #                             collection.
      # @param blank [String, nil] A partial to render when the collection is
      #                            empty. The collection must respond to
      #                            `#empty?`.
      # @return [SafeBuffer] The rendered template.
      def render(
        name,
        object = nil,
        as: :item,
        locals: {},
        spacer: nil,
        blank: nil
      )
        locals = locals.merge(as => object)
        partial = controller.find_partial(name)
        spacer = controller.find_partial(spacer) if spacer
        blank = controller.find_partial(blank) if blank
        buffer = SafeBuffer.new
        list = object.respond_to?(:each) && !object.is_a?(Hash)
        index = 0
        items = list ? object : [object]
        context = controller.send(:helpers)

        if list && blank && items.empty?
          rendered =
            Instrumentation.instrument(
              :request,
              scope: :partial,
              path: blank.path
            ) do
              Zee.app.render_template(blank.path, locals:, request:, context:)
            end

          return SafeBuffer.new(rendered)
        end

        items.each do |item|
          item_locals = locals.merge(as => item, index:)

          if spacer && index.positive?
            rendered =
              Instrumentation.instrument(
                :request,
                scope: :partial,
                path: spacer.path
              ) do
                Zee.app.render_template(
                  spacer.path,
                  locals: item_locals,
                  request:,
                  context:
                )
              end

            buffer << SafeBuffer.new(rendered)
          end

          rendered =
            Instrumentation.instrument(
              :request,
              scope: :partial,
              path: partial.path
            ) do
              Zee.app.render_template(
                partial.path,
                locals: item_locals,
                request:,
                context:
              )
            end

          buffer << SafeBuffer.new(rendered)
          index += 1
        end

        buffer
      end
    end
  end
end
