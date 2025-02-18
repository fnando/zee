# frozen_string_literal: true

module Zee
  class Controller
    module Callbacks
      # @private
      def before_action_callbacks
        @before_action_callbacks ||= []
      end

      # @private
      def skipped_before_action_callbacks
        @skipped_before_action_callbacks ||= Set.new
      end

      def skipped_after_action_callbacks
        @skipped_after_action_callbacks ||= Set.new
      end

      # @private
      def after_action_callbacks
        @after_action_callbacks ||= []
      end

      # @private
      def __normalize_callback_condition(condition)
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
          store: before_action_callbacks,
          method_names:,
          options:,
          block:
        )
      end

      # Define an after action callback.
      def after_action(*method_names, **options, &block)
        define_callback(
          type: :after,
          store: after_action_callbacks,
          method_names:,
          options:, block:
        )
      end

      # Skip a before action callback.
      # @param method_names [Array<Symbol>] The method names to skip.
      def skip_before_action(*method_names)
        skipped_before_action_callbacks.merge(method_names)
      end

      # Skip a after action callback.
      # @param method_names [Array<Symbol>] The method names to skip.
      def skip_after_action(*method_names)
        skipped_after_action_callbacks.merge(method_names)
      end

      # @private
      def build_callback_conditions(options:)
        only = Array(options.delete(:only)).map(&:to_s)
        except = Array(options.delete(:except)).map(&:to_s)
        if_ = __normalize_callback_condition(options.delete(:if))
        unless_ = __normalize_callback_condition(options.delete(:unless))

        [].tap do |conditions|
          conditions << proc { only.include?(action_name) } if only.any?
          conditions << proc { !except.include?(action_name) } if except.any?
          conditions << proc { instance_eval(&if_) } if if_
          conditions << proc { !instance_eval(&unless_) } if unless_
        end
      end

      # @private
      def define_callback(type:, store:, method_names:, options:, block:)
        conditions = build_callback_conditions(options:)

        if method_names.any? && block
          raise ArgumentError, "cannot pass both method names and a block"
        end

        method_names.each do |name|
          handler = proc do
            skipped = self.class
                          .send(:"skipped_#{type}_action_callbacks")
                          .include?(name)

            send(name) unless skipped
          end

          store << [handler, conditions]
        end

        store << [block, conditions] if block
      end
    end
  end
end
