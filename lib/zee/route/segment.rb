# frozen_string_literal: true

module Zee
  class Route
    Segment = Struct.new(:name, :optional?) do
      def inspect
        "#<#{self.class.name} name=#{name.inspect} " \
          "optional=#{optional?.inspect}>"
      end
    end
  end
end
