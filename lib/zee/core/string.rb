# frozen_string_literal: true

module Zee
  module Core
    module String
      BLANK_RE = /\A[[:space:]]*\z/
      UNDERSCORE_RE1 = /([A-Z]+)([A-Z][a-z])/
      UNDERSCORE_RE2 = /([a-z\d])([A-Z])/

      refine ::String do
        def underscore
          gsub(NS_SEPARATOR, SLASH)
            .gsub(UNDERSCORE_RE1, '\1_\2')
            .gsub(UNDERSCORE_RE2, '\1_\2')
            .tr(DASH, UNDERSCORE)
            .downcase
        end

        def camelize
          split(SLASH).map do |part|
            part.split(UNDERSCORE).map(&:capitalize).join
          end.join(NS_SEPARATOR)
        end

        def humanize(keep_id_suffix: false)
          text = underscore
          text = text.sub(/_id$/, EMPTY_STRING) unless keep_id_suffix
          text.tr(UNDERSCORE, SPACE).capitalize
        end

        def blank?
          BLANK_RE.match?(self)
        end

        def present?
          !blank?
        end
      end
    end
  end
end
