# frozen_string_literal: true

module Zee
  class Request < ::Rack::Request
    def path_with_no_trailing_slash
      @path_with_no_trailing_slash ||= begin
        value = path.gsub(%r{^(.+)/+$}, "\\1")
        value.empty? ? "/" : value
      end
    end

    def subdomain
      @subdomain ||= begin
        require "public_suffix"
        PublicSuffix.parse(host).trd.to_s
      end
    end

    def params
      @params ||= super.transform_keys(&:to_sym)
    end
  end
end
