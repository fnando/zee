# frozen_string_literal: true

module Zee
  module ViewHelpers
    module Translation
      # @api internal
      class Translation
        # @api internal
        UNDERSCORE_HTML = "_html"

        # @api internal
        DOT_HTML = ".html"

        # @api internal
        HTML = "html"

        attr_reader :key, :options, :template_path

        def initialize(key:, options:, template_path:)
          @key = key
          @options = options
          @template_path = template_path
        end

        def html_safe_key?
          str_key = key.to_s
          str_key.end_with?(UNDERSCORE_HTML) ||
            str_key == HTML ||
            str_key.end_with?(DOT_HTML)
        end

        def missing_translation(key)
          SafeBuffer.new <<~HTML
            <span class="missing-translation">Missing translation: #{key}</span>
          HTML
        end

        def scoped_by_action_key
          case key
          when Symbol, String
            str_key = key.to_s
            return key unless str_key.start_with?(DOT) && !options[:scope]

            base = template_path
                   .relative_path_from(Zee.app.root.join("app/views"))
                   .to_s
                   .gsub(%r{^(.*?)/_?([^.]+).*?$}, '\1/\2')
                   .tr(SLASH, I18n.default_separator)

            [base, str_key].join(I18n.default_separator)
          else
            key
          end
        end

        def translate
          begin
            translation = I18n.t(scoped_by_action_key, **options, raise: true)
          rescue I18n::MissingTranslationData => error
            raise error if options[:raise]

            return missing_translation(error.keys.join(I18n.default_separator))
          end

          if translation.is_a?(String)
            if html_safe_key?
              SafeBuffer.new(translation)
            else
              SafeBuffer.new + translation
            end
          else
            translation
          end
        end
      end

      # This helper extends `I18n#translate` with three features:
      #
      # 1. Displays missing translations inline as
      #    `<span class="missing-translation">` instead of throwing errors
      # 2. Automatically scopes keys starting with "." to the current partial
      #    (e.g., `.title` in `pages/home.html.erb` becomes `pages.home.title`)
      # 3. Marks translations with "_html" suffix or ".html" ending as
      #    HTML-safe, allowing HTML tags without escaping.
      def translate(key, **options)
        Translation.new(
          key:,
          options:,
          template_path: current_template_path
        ).translate
      end
      alias t translate

      # Delegates to `I18n.localize` with no additional functionality.
      def localize(*, **)
        I18n.l(*, **)
      end
      alias l localize
    end
  end
end
