# frozen_string_literal: true

module Zee
  # Call is a mixin module that provides a class method `call` to create an
  # instance of a class, passing any arguments and keyword arguments to the
  # initializer. It also allows for an optional block to be passed, which is
  # yielded to the instance before calling the `call` method on it.
  #
  # This module is useful for creating service objects or similar patterns
  # where you want to encapsulate the initialization and execution of an object
  # in a single method call.
  #
  # @example
  #   class MyAction
  #     include Zee::Call
  #     include Zee::Listener
  #
  #     def call
  #       emit(:success)
  #     end
  #   end
  #
  #   MyAction.call do |action|
  #     action.on(:success) { puts "Success!" }
  #     action.on(:error) { puts "Error!" }
  #   end
  module Call
    def self.included(target)
      target.extend(ClassMethods)
    end

    module ClassMethods
      def call(*args, **kwargs)
        new(*args, **kwargs).tap do |instance|
          yield(instance) if block_given?
          instance.call
        end
      end
    end
  end
end
