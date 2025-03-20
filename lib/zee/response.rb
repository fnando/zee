# frozen_string_literal: true

module Zee
  class Response
    # The body of the response.
    # @return [String]
    attr_reader :body

    # The template file that's been used to render the response.
    # @return [Controller::Template, nil]
    attr_accessor :view

    # The template file that's been used as the layout file rendered for the
    # response.
    # @return [Controller::Template, nil]
    attr_accessor :layout

    def initialize(body: nil, status: nil, headers: nil)
      @body = body
      @status = status
      @headers = headers
      @performed = false
    end

    # Set the body of the response.
    # @param body [String] the body of the response.
    def body=(body)
      @body = body
      @performed = true
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
      if status
        @status = Rack::Utils.status_code(status)
        @performed = true
      end

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
      @perfomed = false
      headers.clear
    end

    # @api private
    # If status or body is set, mark the response as performed.
    # @return [Boolean]
    def performed?
      @performed
    end
  end
end
