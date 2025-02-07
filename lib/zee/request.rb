# frozen_string_literal: true

module Zee
  class Request < ::Rack::Request
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
