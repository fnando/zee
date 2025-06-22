# frozen_string_literal: true

module Controllers
  class Formats < Base
    def html
      render html: "Hello, World!"
    end

    def html_protocol
      data = Data.define(:to_html).new(to_html: "Hello, World!")

      render html: data
    end

    def xml
      xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <message>Hello, World!</message>
      XML
      render xml:
    end

    def xml_protocol
      to_xml = <<~XML
        <?xml version="1.0" encoding="UTF-8"?>
        <message>Hello, World!</message>
      XML
      data = Data.define(:to_xml).new(to_xml:)

      render xml: data
    end

    def text
      render text: "Hello, World!"
    end

    def json
      render json: {message: "Hello, World!"}
    end
  end
end
