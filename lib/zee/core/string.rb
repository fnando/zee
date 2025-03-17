# frozen_string_literal: true

module Zee
  module Core
    module String
      # @api private
      UNDERSCORE_RE1 = /([A-Z]+)([A-Z][a-z])/

      # @api private
      UNDERSCORE_RE2 = /([a-z\d])([A-Z])/

      # @!method underscore()
      # Makes an underscored, lowercase form from the expression in the
      # string. It will also change `::` to `/` to convert namespaces to
      # paths.
      # @return [String]

      # @!method dasherize()
      # Replaces underscores with dashes in the string.
      # @return [String]
      # @example
      #   "hello_there".dasherize
      #   #=> "hello-there"

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

      refine ::String do
        def inflector
          Zee.app.config.inflector
        end

        def underscore
          inflector.underscore(self)
        end

        def dasherize
          inflector.dasherize(underscore)
        end

        def camelize(first_letter = :upper)
          case first_letter
          when :upper
            inflector.camelize_upper(self)
          when :lower
            inflector.camelize_lower(self)
          else
            raise ArgumentError, "invalid option: #{first_letter.inspect}"
          end
        end

        def humanize(keep_id_suffix: false)
          str = inflector.humanize(self)
          str = "#{str} id" if end_with?("_id") && keep_id_suffix
          str
        end
      end
    end
  end
end
