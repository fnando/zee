# frozen_string_literal: true

module Zee
  class Redirect
    def initialize(location, status)
      @location = location
      @status = status
    end

    def call(_env)
      [@status, {HTTP_LOCATION => @location}, []]
    end

    def to_s
      "#<#{self.class.name} status=#{@status} to=#{@location.inspect}>"
    end
  end
end
