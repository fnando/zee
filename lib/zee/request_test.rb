# frozen_string_literal: true

gem "minitest"
require "minitest"

module Zee
  class RequestTest < Test
    include Rack::Test::Methods
    include Test::Assertions::HTML

    def app
      Zee.app
    end
  end
end
