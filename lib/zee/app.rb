# frozen_string_literal: true

module Zee
  class App
    # The root path of the application.
    attr_accessor :root

    def routes
      @routes ||= Routes.new
    end
  end
end
