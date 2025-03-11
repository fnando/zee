# frozen_string_literal: true

module Controllers
  class Formats < Base
    def text
      render text: "Hello, World!"
    end

    def json
      render json: {message: "Hello, World!"}
    end
  end
end
