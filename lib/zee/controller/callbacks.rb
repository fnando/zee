# frozen_string_literal: true

module Zee
  class Controller
    module Callbacks
      # @private
      def before_action_callbacks
        @before_action_callbacks ||= []
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
        only = Array(options.delete(:only)).map(&:to_s)
        except = Array(options.delete(:except)).map(&:to_s)
        if_ = __normalize_callback_condition(options.delete(:if))
        unless_ = __normalize_callback_condition(options.delete(:unless))

        conditions = []
        conditions << proc { only.include?(action_name) } if only.any?
        conditions << proc { !except.include?(action_name) } if except.any?
        conditions << proc { instance_eval(&if_) } if if_
        conditions << proc { !instance_eval(&unless_) } if unless_

        if method_names.any? && block
          raise ArgumentError, "cannot pass both method names and a block"
        end

        method_names.each do |name|
          before_action_callbacks << [proc { send(name) }, conditions]
        end

        before_action_callbacks << [block, conditions] if block
      end
    end
  end
end
