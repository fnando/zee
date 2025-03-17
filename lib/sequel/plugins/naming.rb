# frozen_string_literal: true

module Sequel
  module Plugins
    # The naming plugin adds a naming method to the model class.
    # It uses the class name and inflector to return the singular and plural
    # form of the name.
    #
    # @example
    #   User.naming.singular # => "user"
    #   Models::User.naming.singular # => "user"
    module Naming
      # @api private
      PREFIX = "Models"

      # @api private
      def self.apply(model)
        model.extend ClassMethods
      end

      module ClassMethods
        # Return the naming object.
        # It strips the `Models` prefix by default.
        #
        # @return [Zee::Naming]
        def naming
          @naming ||= Zee::Naming.new(name, prefix: PREFIX)
        end
      end
    end
  end
end
