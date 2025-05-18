# frozen_string_literal: true

module Controllers
  class Formats < Base
    def html
      render html: "Hello, World!"
    end

    def xml
      xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <message>Hello, World!</message>
      XML
      render xml:
    end

    def text
      render text: "Hello, World!"
    end

    def json
      render json: {message: "Hello, World!"}
    end
  end
end
