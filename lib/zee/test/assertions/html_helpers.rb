# frozen_string_literal: true

module Zee
  class Test < Minitest::Test
    module Assertions
      module HTMLHelpers
        # @api private
        def indent_xsl
          @indent_xsl ||= File.read(File.join(__dir__, "indent.xsl"))
        end

        # Format HTML with indentation.
        # @param html [String] the HTML to be formatted.
        def format_html(html)
          unless html.class.name.start_with?("Nokogiri")
            html = Nokogiri::HTML.fragment(html)
          end

          lines = Nokogiri::XSLT(indent_xsl)
                          .apply_to(Nokogiri::XML(html.to_xml))
                          .lines[2..-1]

          lines ? lines.join : html.to_s.inspect
        end
      end
    end
  end
end
