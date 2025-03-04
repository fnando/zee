# frozen_string_literal: true

module Sequel
  module Plugins
    # The validation plugin extends the default `validation_helpers` plugin with
    # support for localized error messages.
    #
    # The default error messages are defined in
    # `lib/sequel/plugins/validations.yml` and replicated below:
    #
    # ```yml
    # en:
    #   sequel:
    #     errors:
    #       exact_length:
    #         one: "must have exactly one character"
    #         other: "must have exactly %{count} characters"
    #       format: "is invalid"
    #       includes: "must be one of %{list}"
    #       integer: "is not a number"
    #       numeric: "is not a number"
    #       length_range: "must have between %{lower} and %{upper} characters"
    #       not_present: "is not present"
    #       not_null: "is not present"
    #       no_null_byte: "contains a null byte"
    #       type: "must be %{type}"
    #       unique: "is already taken"
    #       max_length:
    #         one: "must be have up to 1 character"
    #         other: "must be have up to %{count} characters"
    #       min_length:
    #         one: "must be have at least 1 character"
    #         other: "must be have at least %{count} characters"
    #       max_value:
    #         one: "must be smaller than %{count}"
    #         other: "must be smaller than %{count}"
    #       min_value:
    #         one: "must be greater than %{count}"
    #         other: "must be greater than %{count}"
    # ```
    #
    # You also can define custom error messages for each attribute. Let's say
    # you'd like to override the `unique` error message.
    #
    # ```yml
    # en:
    #   sequel:
    #     errors:
    #       user:
    #         email:
    #           unique: "this email is already in use"
    # ```
    #
    # @see https://sequel.jeremyevans.net/rdoc-plugins/classes/Sequel/Plugins/ValidationHelpers.html
    module Validations
      module InstanceMethods
        using Zee::Core::String
        using Zee::Core::Array
        PREFIX = "models/"

        def model_name
          @model_name ||= model.name.underscore.delete_prefix(PREFIX)
        end

        private def validates_exact_length(exact, attrs, opts = OPTS)
          Array(attrs).each do |attr|
            super(
              exact,
              attr,
              opts.merge(
                message: translated_error_for(:exact_length, attr, count: exact)
              )
            )
          end
        end

        private def validates_format(with, attrs, opts = OPTS)
          Array(attrs).each do |attr|
            super(
              with,
              attr,
              opts.merge(message: translated_error_for(:format, attr, with:))
            )
          end
        end

        private def validates_includes(list, attrs, opts = OPTS)
          Array(attrs).each do |attr|
            super(
              list,
              attr,
              opts.merge(
                message: translated_error_for(
                  :includes,
                  attr,
                  list: list.inspect
                )
              )
            )
          end
        end

        private def validates_integer(attrs, opts = OPTS)
          Array(attrs).each do |attr|
            super(
              attr,
              opts.merge(message: translated_error_for(:integer, attr))
            )
          end
        end

        private def validates_numeric(attrs, opts = OPTS)
          Array(attrs).each do |attr|
            super(
              attr,
              opts.merge(message: translated_error_for(:numeric, attr))
            )
          end
        end

        private def validates_length_range(range, attrs, opts = OPTS)
          Array(attrs).each do |attr|
            lower = range.first
            upper = range.last

            super(
              range,
              attr,
              opts.merge(
                message: translated_error_for(
                  :length_range,
                  attr,
                  upper:,
                  lower:
                )
              )
            )
          end
        end

        private def validates_max_length(max, attrs, opts = OPTS)
          Array(attrs).each do |attr|
            super(
              max,
              attr,
              opts.merge(
                message: translated_error_for(:max_length, attr, count: max),
                nil_message: translated_error_for(:not_present, attr)
              )
            )
          end
        end

        private def validates_min_length(min, attrs, opts = OPTS)
          Array(attrs).each do |attr|
            super(
              min,
              attr,
              opts.merge(
                message: translated_error_for(:min_length, attr, count: min),
                nil_message: translated_error_for(:not_present, attr)
              )
            )
          end
        end

        private def validates_max_value(max, attrs, opts = OPTS)
          Array(attrs).each do |attr|
            super(
              max,
              attr,
              opts.merge(
                message: translated_error_for(:max_value, attr, count: max)
              )
            )
          end
        end

        private def validates_min_value(min, attrs, opts = OPTS)
          Array(attrs).each do |attr|
            super(
              min,
              attr,
              opts.merge(
                message: translated_error_for(:min_value, attr, count: min)
              )
            )
          end
        end

        private def validates_not_null(attrs, opts = OPTS)
          Array(attrs).each do |attr|
            super(
              attr,
              opts.merge(message: translated_error_for(:not_null, attr))
            )
          end
        end

        private def validates_no_null_byte(attrs, opts = OPTS)
          Array(attrs).each do |attr|
            super(
              attr,
              opts.merge(message: translated_error_for(:no_null_byte, attr))
            )
          end
        end

        private def validates_presence(attrs, opts = OPTS)
          Array(attrs).each do |attr|
            super(
              attr,
              opts.merge(message: translated_error_for(:not_present, attr))
            )
          end
        end

        private def validates_type(type, attrs, opts = OPTS)
          type = Array(type)
          joined_type = type.map { _1.name.downcase }
                            .to_sentence(scope: opts.fetch(:connector, :or))

          Array(attrs).each do |attr|
            super(
              type,
              attr,
              opts.merge(
                message: translated_error_for(:type, attr, type: joined_type)
              )
            )
          end
        end

        private def validates_unique(*attrs)
          opts = {}
          opts.merge!(attrs.pop) if attrs.last.is_a?(Hash)

          Array(attrs).each do |attr|
            super(
              attr,
              opts.merge(message: translated_error_for(:unique, attr))
            )
          end
        end

        # @api private
        private def translated_error_for(type, attr, **)
          I18n.t(
            type,
            **,
            scope: [:sequel, :errors, model_name, attr],
            default: I18n.t(type, **, scope: %i[sequel errors])
          )
        end
      end

      def self.apply(model)
        model.plugin :validation_helpers
        model.include(InstanceMethods)

        I18n.load_path << File.join(__dir__, "validations.yml")
      end
    end
  end
end
