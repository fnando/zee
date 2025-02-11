# frozen_string_literal: true

module Zee
  # The configuration for the application.
  # It uses {https://rubygems.org/gems/superconfig SuperConfig} to define the
  # configuration.
  class Config < SuperConfig::Base
    MissingEnvironmentVariable = Class.new(StandardError)
    MissingCallable = Class.new(StandardError)

    undef_method :credential

    # The application instance.
    # @return [Zee::App]
    attr_reader :app

    def initialize(app = nil, **)
      @app = app
      block = proc { true }
      super(**, &block)
    end

    # @private
    def to_s
      "#<Zee::Config>"
    end
    alias inspect to_s

    # @private
    def mandatory(*, **)
      super
    rescue SuperConfig::MissingEnvironmentVariable => error
      raise MissingEnvironmentVariable, error.message
    end

    # @private
    def property(*, **, &)
      super
    rescue SuperConfig::MissingCallable
      raise MissingCallable,
            "arg[1] must respond to #call or a block must be provided"
    end
  end
end
