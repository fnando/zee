# frozen_string_literal: true

module Controllers
  class Pages < Base
    def home
    end

    def slim
    end

    def missing_template
      render :missing_template
    end

    def hello_ivar
      @message = "Hello, World!"
    end

    def redirect
      redirect_to "/"
    end

    def redirect_error
      redirect_to "https://example.com"
    end

    def redirect_open
      redirect_to "https://example.com", allow_other_host: true
    end

    def custom_layout
      render layout: "custom"
    end

    def no_layout
      render layout: false
    end

    def no_content
      render status: 204
    end
  end
end
