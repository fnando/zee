# frozen_string_literal: true

module Zee
  class Controller
    module Meta
      # @api private
      class Translator
        using Zee::Core::Blank
        include ViewHelpers::Translation

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
          return "" if text.to_s.blank?

          translation = t(
            [
              "zee.meta.#{controller_name_scope}.#{action_name}.#{scope}_base",
              "zee.meta.#{controller_name_scope}.#{scope}_base",
              "zee.meta.#{scope}_base"
            ],
            **options,
            title: text,
            default: ""
          ).find(&:present?)

          (translation || text).to_s
        end

        def text
          current_scope = scope
          current_scope = "#{current_scope}_html" if html

          t(current_scope, scope: base_scope, **options, default: "")
        end

        def base_scope
          @base_scope ||= ["zee", "meta", controller_name_scope, action_name]
                          .join(I18n.default_separator)
        end

        def controller_name_scope
          controller_name.tr(SLASH, I18n.default_separator)
        end

        def current_template_path
          nil
        end
      end
    end
  end
end
