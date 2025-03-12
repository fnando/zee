# frozen_string_literal: true

module Controllers
  class Messages < Base
    skip_before_action :verify_authenticity_token

    def index
    end

    def create
      flash.notice = "Message created."
      redirect_to "/messages"
    end

    def set_keep
      flash.notice = "[NOTICE] Message updated."
      flash.info = "[INFO] Message updated."
      redirect_to "/messages/keep"
    end

    def set_keep_all
      flash.notice = "[NOTICE] Message removed."
      flash.info = "[INFO] Message removed."
      redirect_to "/messages/keep-all"
    end

    def keep
      flash.keep(:notice)
      redirect_to "/messages"
    end

    def keep_all
      flash.keep
      redirect_to "/messages"
    end
  end
end
