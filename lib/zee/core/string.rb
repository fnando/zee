# frozen_string_literal: true

module Zee
  module Core
    module String
      refine ::String do
        def underscore
          gsub("::", "/")
            .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
            .gsub(/([a-z\d])([A-Z])/, '\1_\2')
            .tr("-", "_")
            .downcase
        end

        def camelize
          split("/").map do |part|
            part.split("_").map(&:capitalize).join
          end.join("::")
        end
      end
    end
  end
end
