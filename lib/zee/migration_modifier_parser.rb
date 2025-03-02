# frozen_string_literal: true

module Zee
  # @api private
  class MigrationModifierParser
    InvalidModifierError = Class.new(StandardError)
    Modifier = Struct.new(:name, :sequel_type, :options, keyword_init: true)

    NULL_VALUES = [nil, "true"].freeze

    FIELD_MAPPING = {
      primary_key: ["primary_key"],
      integer: ["Integer", {}],
      string: ["String", {}],
      text: ["String", {text: true}],
      file: ["File", {}],
      blob: ["File", {}],
      bigint: ["Bignum", {}],
      boolean: ["TrueClass", {}],
      float: ["Float", {}],
      date: ["Date", {}],
      datetime: ["Time", {}],
      numeric: ["Numeric", {}]
    }.freeze

    # The raw modifier definition.
    # @return [String]
    attr_reader :input

    def self.call(input)
      new(input).call
    end

    def initialize(input)
      @input = input
    end

    def call
      name, type, *raw_options = input.split(":")

      unless name && type
        raise InvalidModifierError, "Invalid modifier: #{input.inspect}"
      end

      sequel_type, default_options = *expand_type(type)
      default_options ||= {}

      Modifier.new(
        name:,
        sequel_type:,
        options: default_options.merge(parse_options(raw_options))
      )
    end

    private def expand_type(type)
      case type
      when /^numeric\((\d+)(?:,\s*(\d+))?\)$/
        precision = Regexp.last_match(1)
        scale = Regexp.last_match(2)

        size = if scale
                 [precision.to_i, scale.to_i]
               else
                 precision.to_i
               end

        ["BigDecimal", {size:}]
      else
        type = FIELD_MAPPING[type&.to_sym]
        return type if type

        raise InvalidModifierError, "Unsupported type: #{input.inspect}; " \
                                    "add it directly to your migration file"
      end
    end

    private def parse_options(raw_options)
      raw_options.each_with_object({}) do |raw_option, options|
        case raw_option
        when /^null(?:\((true|false)\))?$/
          options[:null] = NULL_VALUES.include?(Regexp.last_match(1))
        when /^index(\((unique)\))?$/
          options[:index] = if Regexp.last_match(1)
                              {unique: true}
                            else
                              true
                            end
        else
          raise InvalidModifierError, "Invalid modifier: #{input.inspect}"
        end
      end
    end
  end
end
