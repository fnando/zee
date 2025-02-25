# frozen_string_literal: true

module Zee
  class Request < ::Rack::Request
    XHR_REGEX = /XMLHttpRequest/i

    # The origin of the request.
    # @return [String, NilClass]
    def origin
      get_header(HTTP_ORIGIN)
    end

    # Returns `true` if the `X-Requested-With` header contains `XMLHttpRequest`
    # (case-insensitive), which may need to be manually added depending on the
    # choice of JavaScript libraries and frameworks.
    # @return [Boolean]
    def xhr?
      XHR_REGEX.match?(get_header(HTTP_X_REQUESTED_WITH).to_s)
    end

    # The path of the request, without any trailing slashes.
    # @return [String]
    # @example
    #   Zee::Request.new("PATH_INFO" => "/").path_with_no_trailing_slash
    #   #=> "/"
    #
    #   Zee::Request.new("PATH_INFO" => "/posts").path_with_no_trailing_slash
    #   #=> "/posts"
    #
    #   Zee::Request.new("PATH_INFO" => "/posts/").path_with_no_trailing_slash
    #   #=> "/posts"
    def path_with_no_trailing_slash
      @path_with_no_trailing_slash ||= begin
        value = path.gsub(%r{^(.+)/+$}, "\\1")
        value.empty? ? SLASH : value
      end
    end

    # The subdomain of the request.
    # This method uses the
    # {https://rubygems.org/gems/public_suffix public_suffix} gem to parse the
    # host.
    # @return [String]
    def subdomain
      @subdomain ||= begin
        require "public_suffix"
        PublicSuffix.parse(host).trd.to_s
      end
    end
  end
end
