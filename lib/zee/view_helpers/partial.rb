# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Partial
      include App::BaseHelper

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
      # ## Partial context
      #
      # Within the partial, you have access to some utility methods:
      #
      # - `first?`: Returns `true` if the current item is the first item in the
      #   collection.
      # - `last?`: Returns `true` if the current item is the last item in the
      #   collection.
      # - `index`: The current item's index in the collection.
      # - `current_template`: A {Template} instance representing the
      #   current template. You can use this to access the template's path or
      #   cache key.
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
        list = object.respond_to?(:each) && !object.is_a?(Hash)
        items = list ? object : [object]
        size = items.size
        iterator = Iterator.new(size)

        locals = locals.merge(
          as => object,
          :@_controller => @_controller,
          :@_iterator => iterator
        )
        partial = controller.find_partial(name)
        spacer = controller.find_partial(spacer) if spacer
        blank = controller.find_partial(blank) if blank
        buffer = SafeBuffer.new
        context = controller.send(:helpers)
                            .clone
                            .extend(Partial)
                            .extend(Utils)

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
          item_locals = locals.merge(as => item)

          if spacer && iterator.index.positive?
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
          iterator.iterate!
        end

        buffer
      end

      def request
        @_request
      end

      # @api private
      # The context object passed to the partial.
      module Utils
        def first?
          @_iterator.first?
        end

        def last?
          @_iterator.last?
        end

        def index
          @_iterator.index
        end
      end

      class Iterator
        # The current index.
        # @return [Integer]
        attr_reader :index

        # The collection size.
        # @return [Integer]
        attr_reader :size

        def initialize(size)
          @size = size
          @index = 0
        end

        # Increments the index.
        # @return [void]
        def iterate!
          @index += 1
        end

        # Return `true` if the index is `0`.
        def first?
          index.zero?
        end

        # Return `true` if the index is the last index.
        def last?
          index == size - 1
        end
      end
    end
  end
end
