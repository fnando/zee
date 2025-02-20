# frozen_string_literal: true

module Zee
  # A simple parameter acessor.
  # This class is used to access body params from a hash-like object.
  # It does basic enforcement of presence and available keys.
  #
  # @example
  #   Zee::Params.new({}).require(:user)
  #   #=> raises Zee::Params::ParameterMissingError
  #
  # @example
  #   Zee::Params.new({user: {}}).require(:user).permit(:username)
  #   #=> {}
  #
  # @example
  #   params = Zee::Params.new({user: {username: "fnando"}})
  #   params.require(:user).permit(:username)
  #   #=> {username: "fnando"}
  #
  # @example
  #   params = Zee::Params.new({user: {username: "fnando"}})
  #   params.require(:user).permit(:name)
  #   #=> raises Zee::Params::UnpermittedParameterError
  class Params < Hash
    ParameterMissingError = Class.new(StandardError)
    UnpermittedParameterError = Class.new(StandardError)

    private :[]=, :merge!, :update, :compact!, :delete, :delete_if,
            :replace, :select!, :shift, :transform_keys!,
            :transform_values!, :default, :default=, :clear, :filter!,
            :reject!

    def initialize(params)
      super()
      params.each {|key, value| self[key] = value }
    end

    # Access a key from the store.
    # @param key [Symbol, String] the key to be accessed.
    # @return [Object] the value associated with the key.
    def [](key)
      value = super(key.to_s)
      value = self.class.new(value) if value.is_a?(Hash)
      value
    end

    # Require a key from the store.
    # @param key [Symbol] the key to be required.
    # @return [Zee::Params] a new instance with the required key.
    # @raise [ParameterMissingError] if the key is not present.
    def require(key)
      key = key.to_s

      raise ParameterMissingError, "param is missing: #{key}" unless key?(key)

      self[key]
    end

    # Permit only the specified keys.
    # @param keys [Array<Symbol>] the keys to be permitted.
    # @return [Hash] a hash with the permitted keys.
    # @raise [UnpermittedParameterError] if there are unpermitted keys.
    def permit(*keys)
      actual_keys = self.keys
      keys = keys.map(&:to_s)
      diff = actual_keys - keys

      if diff.any?
        raise UnpermittedParameterError,
              "found unpermitted keys: #{diff.join(', ')}"
      end

      self.class.new(slice(*keys))
    end
  end
end
