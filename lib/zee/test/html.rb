# frozen_string_literal: true

module Zee
  module Test
    module HTML
      def render(component, *, **)
        Nokogiri::HTML.fragment(component.call, *, **)
      end

      def assert_tag(
        node,
        selector,
        text: nil,
        count: nil,
        debug: false,
        **attrs
      )
        puts node.to_html if debug

        found = node.css(selector)

        if count
          assert_equal count,
                       found.size,
                       "#{selector}\n\n#{node.to_html}"
        else
          assert found.any?,
                 "No tag found matching: #{selector}\n\n#{node.to_html}"
        end

        assert_equal text, found.text if text

        found.each do |element|
          attrs.each do |attr, value|
            assert_equal value, element[attr],
                         "#{element.to_html} does not " \
                         "match #{attr.inspect} => #{value.inspect}"
          end
        end
      end
    end
  end
end
