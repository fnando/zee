# frozen_string_literal: true

module Zee
  class Test < Minitest::Test
    module Assertions
      module HTML
        Minitest::Utils::Reporter.filters << %r{zee/test/assertions/html\.rb}

        # @api private
        def indent_xsl
          @indent_xsl ||= File.read(File.join(__dir__, "indent.xsl"))
        end

        # Asserts that the given HTML contains a tag with the given selector.
        #
        # @param root [Nokogiri::HTML::DocumentFragment] the HTML to be checked.
        # @param selector [String] the tag selector.
        # @param count [Integer] the number of tags to be found.
        # @param minimum [Integer] the minimum number of tags to be found.
        # @param maximum [Integer] the maximum number of tags to be found.
        # @param between [Range] the range number of tags to be found.
        # @param text [String, Regexp, nil] when provided, the tag text must
        #                                   match the given value.
        # @param html [String, Regexp, nil] when provided, the tag's inner html
        #                                   must match the given value.
        def assert_selector(
          root,
          selector,
          count: nil,
          minimum: nil,
          maximum: nil,
          between: nil,
          text: nil,
          html: nil,
          &
        )
          root = Nokogiri::HTML.fragment(root.to_s)
          nodes = root.css(selector)
          lines = Nokogiri::XSLT(indent_xsl)
                          .apply_to(Nokogiri::XML(root.to_xml))
                          .lines[2..-1]

          formatted_root = lines ? lines.join : root.to_s.inspect

          none = (count || minimum || maximum || between).nil?

          minimum = 1 if none

          matched = nodes.count
          matched = 0 if text || html
          matched += nodes.count { match_selector_text(_1, text) } if text
          matched += nodes.count { match_selector_html(_1, html) } if html

          check = if text
                    " with text matching #{text.inspect}"
                  elsif html
                    " with html matching #{html.inspect}"
                  end

          if count && count != matched
            raise Minitest::Assertion,
                  "Expected to find exactly #{count} tag(s) with selector " \
                  "#{selector.inspect}#{check}, but found #{matched}\n\n" \
                  "#{formatted_root}"
          end

          if minimum && matched < minimum
            raise Minitest::Assertion,
                  "Expected to find at least #{minimum} tag(s) with selector " \
                  "#{selector.inspect}#{check}, but found #{matched}\n\n" \
                  "#{formatted_root}"
          end

          if maximum && matched > maximum
            raise Minitest::Assertion,
                  "Expected to find at most #{maximum} tag(s) with selector " \
                  "#{selector.inspect}#{check}, but found #{matched}\n\n" \
                  "#{formatted_root}"
          end

          if between && !between.cover?(matched)
            raise Minitest::Assertion,
                  "Expected to find at between #{between} tag(s) with " \
                  "selector #{selector.inspect}#{check}, but found " \
                  "#{matched}\n\n#{formatted_root}"
          end

          yield nodes if block_given?
          nodes
        end

        # @api private
        def match_selector_text(node, text)
          case text
          when Regexp
            node.text.match?(text)
          else
            node.text == text
          end
        end

        # @api private
        def match_selector_html(node, html)
          case html
          when Regexp
            node.inner_html.to_s.match?(html)
          else
            node.inner_html.to_s == html
          end
        end
      end
    end
  end
end
