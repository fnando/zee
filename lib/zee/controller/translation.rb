# frozen_string_literal: true

module Zee
  class Controller
    module Translation
      # Delegates to `I18n.localize` with no additional functionality.
      private def localize(*, **)
        I18n.l(*, **)
      end
      alias l localize

      # When the given key starts with a period, it will be scoped by the
      # current controller and action. So if you call `translate(".hello")` from
      # MessagesController#show, it will convert the call to
      # `I18n.translate("messages.show.hello")`. This makes it less repetitive
      # to translate many keys within the same controller/action and gives you
      # a simple framework for scoping them consistently.
      private def translate(key, **options)
        if key.is_a?(String) && !options[:scope] && key.start_with?(DOT)
          key = [
            controller_name.tr(SLASH, I18n.default_separator),
            action_name,
            key
          ].join(I18n.default_separator)
        end

        I18n.t(key, **options)
      end
      alias t translate
    end
  end
end
