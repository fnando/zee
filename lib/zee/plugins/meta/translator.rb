# frozen_string_literal: true

module Zee
  module Plugins
    module Meta
      # @api private
      class Translator
        using Zee::Core::Blank
        include ViewHelpers::Translation

        # @api private
        ZEE = "zee"

        # @api private
        META = "meta"

        attr_reader :scope, :controller_name, :action_name, :options, :html

        def initialize(scope:, controller_name:, action_name:, html: false,
                       **options)
          @controller_name = controller_name
          @action_name = action_name
          @scope = scope
          @options = options
          @html = html
        end

        def to_s
          return EMPTY_STRING if text.to_s.blank?

          base_scope = "#{scope}_base"

          translation = t(
            [
              default_join([
                ZEE, META, controller_name, action_name, base_scope
              ]),
              default_join([ZEE, META, controller_name, base_scope]),
              default_join([ZEE, META, base_scope])
            ],
            **options,
            title: text,
            default: EMPTY_STRING
          ).find(&:present?)

          (translation || text).to_s
        end

        def text
          current_scope = scope
          current_scope = "#{current_scope}_html" if html

          t(current_scope, scope: base_scope, **options, default: "")
        end

        def base_scope
          @base_scope ||= default_join([
            ZEE, META, controller_name_scope, action_name
          ])
        end

        def controller_name_scope
          controller_name.tr(SLASH, I18n.default_separator)
        end

        def current_template
          nil
        end

        def default_join(args)
          args.join(I18n.default_separator)
        end
      end
    end
  end
end
