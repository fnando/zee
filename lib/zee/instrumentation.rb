# frozen_string_literal: true

module Zee
  module Instrumentation
    extend self

    def instrumentations
      RequestStore.store[:instrumentation] ||= Hash.new {|h, k| h[k] = [] }
    end

    # Instrument some code. If a block is given, the block is executed and the
    # duration of the block is recorded. The result of the block is returned.
    #
    # @param name [Symbol] the name of the instrumentation.
    # @param kwargs [Hash] the key-value pairs to store.
    # @return [Object] the result of the block.
    def instrument(name, **kwargs)
      if block_given?
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = yield
        duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      end

      instrumentations[name] << {name:, duration:, args: kwargs}

      result
    end
  end
end
