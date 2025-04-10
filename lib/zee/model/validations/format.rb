# frozen_string_literal: true

module Zee
  class Model
    module Validations
      module Format
        DEFAULT_MESSAGE = "is invalid"
        NOT_SUPPLIED_ERROR =
          "Either :with or :without must be supplied (but not both)"
        INVALID_TYPE_ERROR =
          "%{option} must be either Regexp or respond to #call(value)"
        MULTILINE_ERROR =
          "%{option} is using multiline anchors (^ or $) but :multiline is " \
          "not set to true"

        # @api private
        def self.validate_regex!(name, regex, multiline:)
          unless valid_type?(regex)
            raise ArgumentError,
                  format(INVALID_TYPE_ERROR, option: name.inspect)
          end

          return unless multiline != true && multiline_regex?(regex)

          raise ArgumentError, format(MULTILINE_ERROR, option: name.inspect)
        end

        # @api private
        def self.multiline_regex?(regex)
          source = regex.source
          source.start_with?("^") ||
            (source.end_with?("$") && !source.end_with?("\\$"))
        end

        # @api private
        def self.valid_type?(regex)
          regex.is_a?(Regexp) || regex.respond_to?(:call)
        end

        # @api private
        def self.validate(model, attribute, options)
          value = model[attribute].to_s

          return if options[:with] && options[:with] === value
          return if options[:without] && !(options[:without] === value)

          translated_message = Validations.error_message(
            :format,
            model,
            attribute
          )

          message = [translated_message, options[:message], DEFAULT_MESSAGE]
                    .compact
                    .first

          model.errors_with_details[attribute].push(
            {error: :format, message:}
          )
        end

        # This method is used to validate the acceptance of attributes.
        #
        # @param names [Symbol] The names of the attributes to validate.
        # @param options [Hash] The options for the validation.
        # @option options [String] :message The error message to use if the
        #                                   validation fails.
        # @option options [Symbol] :if A condition to check before validating.
        # @option options [Symbol] :unless A condition to check before
        #                                  validating.
        # @option options [Symbol] :allow_nil Whether to allow nil values.
        # @option options [Symbol] :allow_blank Whether to allow blank values.
        # @option options [Boolean] multiline Set to `true` if your regular
        #                                     expression contains anchors that
        #                                     match the beginning or end of
        #                                     lines as opposed to the beginning
        #                                     or end of the string. These
        #                                     anchors are `^` and `$`.
        def validates_format_of(*names, **options)
          if options[:with] && options[:without]
            raise ArgumentError, NOT_SUPPLIED_ERROR
          end

          unless options.include?(:with) ^ options.include?(:without)
            raise ArgumentError, NOT_SUPPLIED_ERROR
          end

          options.slice(:with, :without).each do |name, value|
            Format.validate_regex!(name, value, multiline: options[:multiline])
          end

          validations << Validator.new(Format, names, options)
        end
      end
    end
  end
end
