# frozen_string_literal: true

module Zee
  module Core
    module String
      # @api private
      BLANK_RE = /\A[[:space:]]*\z/

      # @api private
      UNDERSCORE_RE1 = /([A-Z]+)([A-Z][a-z])/

      # @api private
      UNDERSCORE_RE2 = /([a-z\d])([A-Z])/

      # @!method underscore()
      # Makes an underscored, lowercase form from the expression in the
      # string. It will also change `::` to `/` to convert namespaces to
      # paths.
      # @return [String]

      # @!method camelize(type = :upper)
      # @param type [Symbol] the type of camelization. Can be `:upper` or
      #                      `:lower`.
      # By default, camelize converts strings to `UpperCamelCase`. If the
      # argument to camelize is set to `:lower` then camelize produces
      # `lowerCamelCase`.
      # @return [String]

      # @!method humanize()
      # Tweaks an attribute name for display to end users.
      # @return [String]

      # @!method blank?()
      # Returns `true` if the string is empty or contains whitespaces only.
      # @return [Boolean]

      # @!method present?()
      # Returns `true` if the string is not empty and contains non-whitespace
      # characters.
      # @return [Boolean]

      refine ::String do
        def underscore
          gsub(NS_SEPARATOR, SLASH)
            .gsub(UNDERSCORE_RE1, '\1_\2')
            .gsub(UNDERSCORE_RE2, '\1_\2')
            .tr(DASH, UNDERSCORE)
            .downcase
        end

        def camelize(first_letter = :upper)
          text =
            split(SLASH)
            .map {|part| part.split(UNDERSCORE).map(&:capitalize).join }
            .join(NS_SEPARATOR)

          case first_letter
          when :upper
            text
          when :lower
            text[0].downcase + text[1..-1]
          else
            raise ArgumentError, "invalid option: #{first_letter.inspect}"
          end
        end

        def humanize(keep_id_suffix: false)
          text = underscore
          text = text.delete_prefix(UNDERSCORE)
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
