# frozen_string_literal: true

module Zee
  module Encoders
    # The JSON encoder.
    # This encoder symbolizes the keys when parsing the JSON data.
    module JSONEncoder
      def self.dump(data)
        ::JSON.dump(data)
      end

      def self.parse(data)
        ::JSON.parse(data, symbolize_names: true)
      end
    end
  end
end
