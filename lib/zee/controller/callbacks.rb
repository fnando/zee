# frozen_string_literal: true

module Zee
  class Controller
    module Callbacks
      using Core::Blank

      def self.included(base)
        base.extend(Callbacks::ClassMethods)
      end

      module ClassMethods
        # @api private
        def inherited(subclass)
          super

          callbacks
            .each {|type, list| subclass.callbacks[type] = list.dup }

          skipped_callbacks
            .each {|type, list| subclass.skipped_callbacks[type] = list.dup }
        end

        # @api private
        def callbacks
          @callbacks ||= {before: [], after: []}
        end

        # @api private
        def skipped_callbacks
          @skipped_callbacks ||= {before: [], after: []}
        end

        # @api private
        def normalize_callback_condition(condition)
          if condition.is_a?(Symbol) || condition.is_a?(String)
            proc { send(condition) }
          else
            condition
          end
        end

        # Define a before action callback.
        def before_action(*method_names, **options, &block)
          define_callback(
            type: :before,
            store: callbacks[:before],
            method_names:,
            options:,
            block:
          )
        end

        # Define an after action callback.
        def after_action(*method_names, **options, &block)
          define_callback(
            type: :after,
            store: callbacks[:after],
            method_names:,
            options:, block:
          )
        end

        # Skip a before action callback.
        #
        # @param method_names [Array<Symbol>] The method names to skip.
        # @param options [Hash] The options to skip the callback.
        # @see #before_action
        def skip_before_action(*method_names, **options)
          conditions = build_callback_conditions(options:)
          skipped_callbacks[:before] << [method_names, conditions]
        end

        # Skip a after action callback.
        #
        # @param method_names [Array<Symbol>] The method names to skip.
        # @param options [Hash] The options to skip the callback.
        # @see #before_action
        def skip_after_action(*method_names, **options)
          conditions = build_callback_conditions(options:)
          skipped_callbacks[:after] << [method_names, conditions]
        end

        # @api private
        def build_callback_conditions(options:)
          only = Array(options.delete(:only)).map(&:to_s)
          except = Array(options.delete(:except)).map(&:to_s)
          if_ = normalize_callback_condition(options.delete(:if))
          unless_ = normalize_callback_condition(options.delete(:unless))

          conditions = []
          conditions << proc { only.include?(action_name) } if only.any?
          conditions << proc { !except.include?(action_name) } if except.any?
          conditions << proc { instance_eval(&if_) } if if_
          conditions << proc { !instance_eval(&unless_) } if unless_

          proc { conditions.all? { instance_eval(&_1) } }
        end

        # @api private
        def define_callback(type:, store:, method_names:, options:, block:)
          conditions = build_callback_conditions(options:)

          if method_names.any? && block
            raise ArgumentError, "cannot pass both method names and a block"
          end

          method_names.each do |name|
            handler = proc do
              send(name) unless skip_callback?(type:, name:)
            end

            store << [handler, conditions, name]
          end

          store << [block, conditions] if block
        end
      end

      # @api private
      def skip_callback?(type:, name:)
        self.class.skipped_callbacks[type].any? do |names, condition|
          names.include?(name) && instance_eval(&condition)
        end
      end

      # @api private
      private def instrument_before_action(name, callback, response)
        return unless Zee.app.config.enable_instrumentation?

        source = name
        source ||= begin
          file, line = callback.source_location
          [Pathname(file).relative_path_from(Dir.pwd), line].join(COLON)
        end

        props = {source: name ? ":#{name}" : source, scope: :before_action}
        location = response.headers[:location]
        props[:redirected_to] = location unless location.blank?

        instrument :request, **props
      end
    end
  end
end
