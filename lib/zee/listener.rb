# frozen_string_literal: true

module Zee
  # The `Zee::Listener` module provides a way to create observable objects that
  # can emit events and allow listeners to subscribe to those events.
  #
  # @example
  #   class MyClass
  #     include Zee::Listener
  #
  #     def initialize
  #       on(:ready) { puts "Ready!" }
  #     end
  #
  #     def ready
  #       emit(:ready)
  #     end
  #   end
  module Listener
    # Add `on` listener for an event.
    #
    # @param event [Symbol] The event name.
    # @yield [*, **] The block to be executed when the event is emitted.
    # @yieldreturn [void]
    # @return [self] The current object.
    #
    # @example
    #   record.on(:ready) { puts "Ready!" }
    def on(event, &)
      listeners << Listener.new(self, __method__, event, &)
      self
    end

    # Add `before` listener for an event.
    #
    # @param event [Symbol] The event name.
    # @yield [*, **] The block to be executed before the event is emitted.
    # @yieldreturn [void]
    # @return [self] The current object.
    #
    # @example
    #   record.before(:ready) { puts "Preparing..." }
    def before(event, &)
      listeners << Listener.new(self, __method__, event, &)
      self
    end

    # Add `after` listener for an event.
    #
    # @param event [Symbol] The event name.
    # @yield [*, **] The block to be executed after the event is emitted.
    # @yieldreturn [void]
    # @return [self] The current object.
    #
    # @example
    #   record.after(:ready) { puts "Finished!" }
    def after(event, &)
      listeners << Listener.new(self, __method__, event, &)
      self
    end

    # Add a listener for an event.
    #
    # @param listener [Object] The listener object that responds to the event.
    # @return [self] The current object.
    #
    # @example
    #   class MyListener
    #     def on_ready
    #       puts "Ready!"
    #     end
    #
    #     def before_ready
    #       puts "Preparing..."
    #     end
    #
    #     def after_ready
    #       puts "Finished!"
    #     end
    #   end
    #
    #   record.add_listener(MyListener.new)
    #   record.emit(:ready)
    def add_listener(listener)
      listeners << listener
      self
    end

    # Emit an event, triggering all listeners for that event.
    #
    # ## Lifecycle
    #
    # - emits `before` event
    # - emits `on` event
    # - emits `after` event
    #
    # @example
    #   record.emit(:ready)
    #   record.emit(:success, "/redirect/to/path")
    def emit(event, *, **)
      emit_signal(:before, event, *, **)
      emit_signal(:on, event, *, **)
      emit_signal(:after, event, *, **)
      self
    end

    # Listeners for this object.
    def listeners
      @listeners ||= []
    end

    private def emit_signal(type, event, *args)
      listeners.each do |listener|
        method_name = "#{type}_#{event}"

        if listener.respond_to?(method_name, true)
          listener.send(method_name, *args)
        end
      end
    end
  end
end
