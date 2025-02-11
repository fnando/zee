# frozen_string_literal: true

module Controllers
  class Formats < Zee::Controller
    def text
      render text: "Hello, World!"
    end
  end
end
