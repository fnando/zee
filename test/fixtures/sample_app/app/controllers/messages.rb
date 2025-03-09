# frozen_string_literal: true

module Controllers
  class Messages < Zee::Controller
    def index
    end

    def create
      flash.notice = "Message created."
      redirect_to "/messages"
    end
  end
end
