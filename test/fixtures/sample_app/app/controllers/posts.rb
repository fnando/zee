# frozen_string_literal: true

module Controllers
  class Posts < Base
    def new
      render text: authenticity_token
    end

    def create
      render text: "post created"
    end
  end
end
