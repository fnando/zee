# frozen_string_literal: true

module Zee
  class Naming
    using Core::String

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
        str = str.delete_prefix("#{@inflector.underscore(@prefix)}/") if @prefix
        str
      end
    end
  end
end
