# frozen_string_literal: true

module Zee
  module Instrumentation
    def instrument(name, **kwargs)
      if block_given?
        start = Process.clock_gettime(Process::CLOCK_MONOTONIC)
        result = yield
        duration = Process.clock_gettime(Process::CLOCK_MONOTONIC) - start
      end

      RequestStore.store[:instrumentation] ||= Hash.new {|h, k| h[k] = [] }
      RequestStore.store[:instrumentation][name] << [duration, kwargs]

      result
    end
  end
end
