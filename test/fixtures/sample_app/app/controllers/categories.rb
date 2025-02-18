# frozen_string_literal: true

module Controllers
  class Categories < Base
    def new
      render text: authenticity_token(
        request_method: :post,
        path: "/categories/new"
      )
    end

    def create
      render text: "category created"
    end
  end
end
