# frozen_string_literal: true

module Controllers
  class AuthBase < Zee::Controller
    include Zee::Plugins::Auth
    auth_scope :user,
               when_logged_in: proc { redirect_to dashboard_path },
               when_logged_out: proc { redirect_to login_path }

    private def current_user
      {email: session[:user_id]} if session[:user_id]
    end
  end
end
