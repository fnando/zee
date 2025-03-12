# frozen_string_literal: true

module Controllers
  class Base < Zee::Controller
    include Zee::Plugins::Meta
    before_action :verify_authenticity_token
  end
end
