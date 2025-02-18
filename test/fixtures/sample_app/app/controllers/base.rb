# frozen_string_literal: true

module Controllers
  class Base < Zee::Controller
    before_action :verify_authenticity_token
  end
end
