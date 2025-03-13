# frozen_string_literal: true

module Zee
  class Response
    # The body of the response.
    # @return [String]
    attr_accessor :body

    # The template file that's been used to render the response.
    # @return [Controller::Template, nil]
    attr_accessor :view_path

    # The template file that's been used as the layout file rendered for the
    # response.
    # @return [Controller::Template, nil]
    attr_accessor :layout_path

    def initialize(body: nil, status: nil, headers: nil)
      @body = body
      @status = status
      @headers = headers
    end

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

    # Set the status code of the response.
    # @param status [Integer, Symbol, nil] the status code. When nil, the status
    #                                      code will be unset.
    def status=(status)
      status(status)
      @status = nil unless status
    end

    # The headers of the response.
    # @return [Zee::Headers]
    def headers
      @headers ||= Headers.new
    end

    # Reset the response.
    def reset
      @body = nil
      @status = nil
      headers.clear
    end
  end
end
