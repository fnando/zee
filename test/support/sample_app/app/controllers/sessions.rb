# frozen_string_literal: true

module Controllers
  class Sessions < Zee::Controller
    def show
      render text: session[:user_id]
    end

    def create
      session[:user_id] = 1234
      render text: ""
    end

    def delete
      reset_session
      render text: ""
    end
  end
end
