# frozen_string_literal: true

module Zee
  class Response
    # The body of the response.
    attr_accessor :body

    def status(status = nil)
      @status = Rack::Utils.status_code(status) if status
      @status
    end

    def headers
      @headers ||= Headers.new
    end
  end
end
