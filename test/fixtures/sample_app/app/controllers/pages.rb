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
  end
end
