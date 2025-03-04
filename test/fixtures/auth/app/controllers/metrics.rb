# frozen_string_literal: true

module Controllers
  class Metrics < AuthBase
    before_action :require_logged_user

    def show
      render text: "metrics"
    end

    private def authorized_user?
      current_user[:email].match?(/\Aadmin@/)
    end
  end
end
