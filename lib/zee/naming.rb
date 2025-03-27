# frozen_string_literal: true

module Zee
  # A module that provides naming utilities for classes and modules.
  # It's used to get the singular and plural form of the class/module name.
  #
  # By default, it uses the global inflector, that's defined
  # in `Zee.app.config.inflector`. To use a custom inflector,
  # define the `.naming` method manually and pass the inflector as an argument.
  #
  # @example Using default inflector
  #   class User
  #     extend Zee::Naming
  #   end
  #
  #   User.naming.singular # => "user"
  #   User.naming.plural # => "users"
  #
  # @example Providing a custom inflector
  #   class User
  #     def self.naming
  #       @naming ||= Zee::Naming::Name.new(name, inflector: MyInflector)
  #     end
  #   end
  #
  # @example Using a prefix
  #   module Models
  #     class User
  #       def self.naming
  #         @naming ||= Zee::Naming::Name.new(name, prefix: "Models")
  #       end
  #     end
  #   end
  #
  #   Models::User.naming.singular # => "user"
  module Naming
    # @api private
    def self.extended(target)
      target.extend(ClassMethods)
    end

    module ClassMethods
      # Return the name of the class in different variations.
      #
      # @return [Zee::Name]
      #
      # @example
      #  class User
      #    extend Zee::Naming
      #  end
      #
      #  User.naming.singular #=> "user"
      #  User.naming.plural #=> "users"
      #  User.naming.underscore #=> "user"
      def naming
        @naming ||= Name.new(name)
      end
    end

    class Name
      # Return the class name.
      # @return [String]
      attr_reader :name

      def initialize(name, prefix: nil, inflector: Zee.app.config.inflector)
        @name = name
        @prefix = prefix
        @inflector = inflector
      end

      # Return the plural form of the name.
      # @return [String]
      # @example
      #   Zee::Naming.new("Users").plural # => "users"
      def plural
        @plural ||= @inflector.pluralize(singular)
      end

      # Return the singular form of the name.
      # @return [String]
      # @example
      #   Zee::Naming.new("Users").singular # => "user"
      def singular
        @singular ||= begin
          str = @inflector.underscore(name)

          if @prefix
            str = str.delete_prefix("#{@inflector.underscore(@prefix)}/")
          end

          @inflector.singularize(str)
        end
      end

      # Return the singular form of the name.
      # @return [String]
      # @example
      #   Zee::Naming.new("User").underscore # => "user"
      #   Zee::Naming.new("Admin::User").underscore # => "admin/user"
      def underscore
        @underscore ||= begin
          str = @inflector.underscore(name)

          if @prefix
            str = str.delete_prefix("#{@inflector.underscore(@prefix)}/")
          end

          str
        end
      end
    end
  end
end
