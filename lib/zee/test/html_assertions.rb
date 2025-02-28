# frozen_string_literal: true

module Zee
  class Test < Minitest::Test
    module HTMLAssertions
      # Asserts that the given HTML contains a tag with the given selector.
      #
      # @param root [Nokogiri::HTML::DocumentFragment] the HTML to be checked.
      # @param selector [String] the tag selector.
      # @param count [Integer] the number of tags to be found.
      # @param text [String, Regexp, nil] when provided, the tag text must match
      #                                   the given value.
      # @param html [String, Regexp, nil] when provided, the tag's inner html
      #                                   must match the given value.
      def assert_tag(root, selector, count: 1, text: nil, html: nil)
        root = Nokogiri::HTML.fragment(root.to_s)
        nodes = root.css(selector)

        assert_equal count,
                     nodes.size,
                     "Expected to find #{count} tag(s) with selector " \
                     "#{selector.inspect}, but found #{nodes.size}"

        nodes.each { assert_tag_text(_1, text) } if text
        nodes.each { assert_tag_html(_1, html) } if html
      end

      def assert_tag_text(node, text)
        case text
        when Regexp

          assert_match text, node.text
        else
          assert_equal text, node.text
        end
      end

      def assert_tag_html(node, html)
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
