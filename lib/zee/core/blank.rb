# frozen_string_literal: true

module Zee
  module Core
    module Blank
      # @api private
      BLANK_RE = /\A[[:space:]]*\z/

      # @!method blank?()
      # Returns `true` if array is empty.
      # @return [Boolean]
      #
      # @!method present?()
      # Returns `true` if array has items.
      # @return [Boolean]
      refine ::Array do
        def blank?
          empty?
        end

        def present?
          any?
        end
      end

      # @!method blank?()
      # Returns `true` if hash is empty.
      # @return [Boolean]
      #
      # @!method present?()
      # Returns `true` if hash has items.
      # @return [Boolean]
      refine ::Hash do
        def blank?
          empty?
        end

        def present?
          any?
        end
      end

      # @!method blank?()
      # Returns `true` if the string is empty or contains whitespaces only.
      # @return [Boolean]
      #
      # @!method present?()
      # Returns `true` if the string is not empty and contains non-whitespace
      # characters.
      # @return [Boolean]
      refine ::String do
        def blank?
          BLANK_RE.match?(self)
        end

        def present?
          !blank?
        end
      end

      # @!method blank?()
      # Returns `false`.
      # @return [Boolean]
      #
      # @!method present?()
      # Returns `true`.
      # @return [Boolean]
      refine ::Symbol do
        def blank?
          false
        end

        def present?
          true
        end
      end

      # @!method blank?()
      # Returns `true`.
      # @return [Boolean]
      #
      # @!method present?()
      # Returns `false`.
      # @return [Boolean]
      refine ::NilClass do
        def blank?
          true
        end

        def present?
          false
        end
      end

      # @!method blank?()
      # Returns `false`.
      # @return [Boolean]
      #
      # @!method present?()
      # Returns `true`.
      # @return [Boolean]
      refine ::Numeric do
        def blank?
          false
        end

        def present?
          true
        end
      end
    end
  end
end
