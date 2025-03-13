# frozen_string_literal: true

module Zee
  class Controller
    module ErrorHandling
      def self.included(controller)
        controller.extend(ClassMethods)
      end

      module ClassMethods
        # @api private
        def inherited(subclass)
          super

          subclass.rescue_handlers.push(*rescue_handlers)
        end

        def rescue_handlers
          @rescue_handlers ||= []
        end

        # Registers exception classes with a handler to be called whenever
        # there's and error during an action.
        #
        # @example Using a method name
        #   ```ruby
        #   module Controllers
        #     class Posts < Base
        #       rescue_from Exception, with: :handle_error
        #
        #       private def handle_error(error)
        #         render :error, status: :internal_server_error
        #       end
        #     end
        #   end
        #   ```
        #
        # @example Using a block
        #   ```ruby
        #   module Controllers
        #     class Posts < Base
        #       rescue_from Exception do
        #         render :error, status: :internal_server_error
        #       end
        #     end
        #   end
        #   ```
        def rescue_from(*exceptions, with: nil, &block)
          block ||= proc {|error| send(with, error) }

          exceptions.each do |_exception|
            rescue_handlers << {exceptions: exceptions, with: block}
          end
        end
      end
    end
  end
end
