# frozen_string_literal: true

module Controllers
  class Pages < Zee::Controller
    def home
    end

    def missing_template
      render :missing_template
    end

    def hello
      expose message: "Hello, World!"
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
  end
end
