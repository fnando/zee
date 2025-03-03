# frozen_string_literal: true

module Zee
  class Environment
    # @api private
    NAMES = %i[development test production local].freeze

    # Returns the name of the environment.
    # @return [Symbol]
    attr_reader :name

    # Initialize the environment.
    # @param name [String, Symbol] The name of the environment.
    def initialize(name)
      @name = name.to_sym

      return if NAMES.include?(@name)

      raise ArgumentError, "Invalid environment: #{@name.inspect}"
    end

    # Returns true if the environment is development.
    # @return [Boolean]
    def development?
      name == :development
    end

    # Returns true if the environment is test.
    # @return [Boolean]
    def test?
      name == :test
    end

    # Returns true if the environment is production.
    # @return [Boolean]
    def production?
      name == :production
    end

    # Returns true if the environment is local (either `test` or `development`).
    # @return [Boolean]
    def local?
      test? || development?
    end

    # Implements equality for the environment.
    # @param other [Symbol, String] The environment to compare.
    # @return [Boolean]
    def ==(other)
      name == other || name.to_s == other
    end
    alias eql? ==
    alias equal? ==
    alias === ==

    # Returns the name of the environment as a symbol.
    # @return [Symbol]
    def to_sym
      name
    end

    # Returns the name of the environment as a string.
    # @return [String]
    def to_s
      name.to_s
    end

    # Returns the name of the environment as a string.
    # @return [String]
    def inspect
      to_s.inspect
    end

    # Yields a block if the environment is the same as the given environment.
    # - To match all environments use `:any` or `:all`.
    # - To match local environments use `:local`.
    # @param envs [Array<Symbol>] The environment(s) to check.
    #
    # @example
    #   app.env.on(:development) do
    #     # Code to run in development
    #   end
    def on(*envs)
      matched = envs.include?(:any) ||
                envs.include?(:all) ||
                envs.include?(name) ||
                (envs.include?(:local) && local?)

      yield if matched
    end
  end
end
