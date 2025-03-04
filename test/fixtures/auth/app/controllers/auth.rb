# frozen_string_literal: true

module Controllers
  class Auth < Zee::Controller
    include Zee::Controller::Auth
    auth_scope :user

    def index
      expose user: {}
    end
  end
end
