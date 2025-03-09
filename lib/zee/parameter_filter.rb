# frozen_string_literal: true

module Zee
  # Filter parameters from logs and exceptions.
  # This is useful to avoid leaking sensitive information.
  #
  # By default, the following parameter keys  are filtered:
  #
  # - `passw`
  # - `email`
  # - `secret`
  # - `token`
  # - `_key`
  # - `crypt`
  # - `salt`
  # - `certificate`
  # - `otp`
  # - `ssn`
  # - `cvv`
  # - `cvc`
  #
  # > [!NOTICE]
  # > Remember that this filter performs partial matching. For example, the
  # > `email` filter will match any parameter key that contains the word
  # > `email`, like `email` and `user_email`.
  class ParameterFilter
    # @api private
    DEFAULT_MASK = "[filtered]"

    # @api private
    DEFAULT_FILTERS = %w[
      passw email secret token _key crypt salt certificate otp ssn cvv cvc
    ].freeze

    def initialize(filters = DEFAULT_FILTERS)
      @filter = Regexp.union(filters.map(&:to_s))
    end

    def filter(params, mask: DEFAULT_MASK)
      filter_object(params.dup, mask)
    end

    def filter_object(object, mask)
      case object
      when Hash
        object.each do |key, value|
          object[key] = if key.to_s.match?(@filter)
                          mask
                        else
                          filter_object(value, mask)
                        end
        end
      when Array
        object = object.map { filter_object(_1, mask) }
      end

      object
    end
  end
end
