# frozen_string_literal: true

module Zee
  class FormBuilder
    class Layout < Base
      attr_reader :input, :label, :hint

      def initialize(input:, label:, hint:)
        super()
        @input = input
        @label = label
        @hint = hint
      end

      def view_template
        div(class: "field") do
          div(class: "field--group") do
            render label
            render hint if hint
          end
          render input
        end
      end
    end
  end
end
