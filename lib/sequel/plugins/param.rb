# frozen_string_literal: true

module Sequel
  module Plugins
    # The param plugin adds a `to_param` method to the model instance.
    #
    # This method returns a string that can be used as a URL parameter for the
    # model instance.
    module Param
      module InstanceMethods
        # Returns a string that can be used as a URL parameter for the model
        # instance.
        #
        # Assumes the instance has an `id` attribute. This can be overridden
        # by defining a `to_param` method in the model.
        #
        # @return [String] the id of the model instance.
        #
        # @example
        # model = MyModel[1]
        # model.to_param
        # #=> "1"
        def to_param
          id
        end
      end

      # @api private
      def self.apply(model)
        model.include(InstanceMethods)
      end
    end
  end
end
