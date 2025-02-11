module Zee
  class Response
    # The body of the response.
    # @return [String]
    attr_accessor :body

    # The status code of the response.
    # @return [Integer] The status code when set.
    # @return [NilClass] The status code when not set.
    #
    # @example Set the status code using integer.
    #   response.status(200)
    #
    # @example Set the status code using symbol.
    #   response.status(:ok)
    #
    # @example Get the status code.
    #   response.status
    def status(status = nil)
      @status = Rack::Utils.status_code(status) if status
      @status
    end

    # The headers of the response.
    # @return [Zee::Headers]
    def headers
      @headers ||= Headers.new
    end
  end
end
