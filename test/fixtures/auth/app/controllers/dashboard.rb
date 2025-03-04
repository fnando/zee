# frozen_string_literal: true

module Controllers
  class Dashboard < AuthBase
    before_action :require_logged_user

    def show
    end
  end
end
