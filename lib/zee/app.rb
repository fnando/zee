# frozen_string_literal: true

module Zee
  class App
    # The root path of the application.
    attr_accessor :root

    def initialize(&)
      instance_eval(&) if block_given?
    end

    # Define the app's routes.
    # See [Zee::Routes].
    def routes(&)
      @routes ||= Routes.new
      @routes.instance_eval(&) if block_given?
      @routes
    end
  end
end
