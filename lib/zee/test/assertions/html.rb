# frozen_string_literal: true

module Zee
  class Test < Minitest::Test
    module Assertions
      module HTML
        Minitest::Utils::Reporter.filters << %r{zee/test/assertions/html\.rb}

        def indent_xsl
          @indent_xsl ||= File.read(File.join(__dir__, "indent.xsl"))
        end

        # Asserts that the given HTML contains a tag with the given selector.
        #
        # @param root [Nokogiri::HTML::DocumentFragment] the HTML to be checked.
        # @param selector [String] the tag selector.
        # @param count [Integer] the number of tags to be found.
        # @param text [String, Regexp, nil] when provided, the tag text must
        #                                   match the given value.
        # @param html [String, Regexp, nil] when provided, the tag's inner html
        #                                   must match the given value.
        def assert_selector(root, selector, count: 1, text: nil, html: nil, &)
          root = Nokogiri::HTML.fragment(root.to_s)
          nodes = root.css(selector)
          formatted_root = Nokogiri::XSLT(indent_xsl)
                                   .apply_to(Nokogiri::XML(root.to_xml))
                                   .lines[2..-1]
                                   .join

          assert_equal count,
                       nodes.size,
                       "Expected to find #{count} tag(s) with selector " \
                       "#{selector.inspect}, but found #{nodes.size}\n\n" \
                       "#{formatted_root}"

          nodes.each { assert_selector_text(_1, text) } if text
          nodes.each { assert_selector_html(_1, html) } if html

          yield nodes if block_given?
          nodes
        end

        def assert_selector_text(node, text)
          case text
          when Regexp

            assert_match text, node.text
          else
            assert_equal text, node.text
          end
        end

        def assert_selector_html(node, html)
          case html
          when Regexp

            assert_match html, node.inner_html.to_s
          else
            assert_equal html, node.inner_html.to_s
          end
        end
      end
    end
  end
end
