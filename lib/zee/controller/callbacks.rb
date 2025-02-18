# frozen_string_literal: true

module Zee
  class Controller
    module Callbacks
      module ClassMethods
        # @private
        def reset_callbacks!
          callbacks[:before].clear
          callbacks[:after].clear
          skipped_callbacks[:before].clear
          skipped_callbacks[:after].clear
        end

        # @private
        def callbacks
          @callbacks ||= {before: [], after: []}
        end

        # @private
        def skipped_callbacks
          @skipped_callbacks ||= {before: [], after: []}
        end

        # @private
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
        # @param method_names [Array<Symbol>] The method names to skip.
        # @param options [Hash] The options to skip the callback.
        # @see #before_action
        def skip_before_action(*method_names, **options)
          conditions = build_callback_conditions(options:)
          skipped_callbacks[:before] << [method_names, conditions]
        end

        # Skip a after action callback.
        # @param method_names [Array<Symbol>] The method names to skip.
        # @param options [Hash] The options to skip the callback.
        # @see #before_action
        def skip_after_action(*method_names, **options)
          conditions = build_callback_conditions(options:)
          skipped_callbacks[:after] << [method_names, conditions]
        end

        # @private
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

        # @private
        def define_callback(type:, store:, method_names:, options:, block:)
          conditions = build_callback_conditions(options:)

          if method_names.any? && block
            raise ArgumentError, "cannot pass both method names and a block"
          end

          method_names.each do |name|
            handler = proc do
              send(name) unless skip_callback?(type:, name:)
            end

            store << [handler, conditions]
          end

          store << [block, conditions] if block
        end
      end

      # @private
      def skip_callback?(type:, name:)
        self.class.skipped_callbacks[type].any? do |names, condition|
          names.include?(name) && instance_eval(&condition)
        end
      end
    end
  end
end
