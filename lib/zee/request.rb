# frozen_string_literal: true

module Zee
  class Request < ::Rack::Request
    def params
      @params ||= super.transform_keys(&:to_sym)
    end
  end
end
