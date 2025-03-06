# frozen_string_literal: true

module Controllers
  class Login < AuthBase
    before_action :redirect_logged_user

    def new
      expose user: {}
    end

    def create
      create_user_session user_params[:email]
      redirect_to return_to(dashboard_path)
    end

    private def user_params
      params.require(:user).permit(:email)
    end
  end
end
