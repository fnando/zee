# frozen_string_literal: true

module Zee
  module Core
    module Numeric
      # @api private
      NANOSECOND = "ns"

      # @api private
      MICROSECOND = "μs"

      # @api private
      MILLISECOND = "ms"

      # @api private
      SECOND = "s"

      # @api private
      TRAILING_ZERO_RE = /0+$/

      # @api private
      DURATION_FORMAT = "%.2f"

      refine ::Numeric do
        # @!method duration
        #  Formats the number (seconds) as a duration.
        #  @return [String] the formatted duration.
        def duration
          duration_ns = self * 1_000_000_000

          number, unit = if duration_ns < 1000
                           [duration_ns, NANOSECOND]
                         elsif duration_ns < 1_000_000
                           [duration_ns / 1000, MICROSECOND]
                         elsif duration_ns < 1_000_000_000
                           [duration_ns / 1_000_000, MILLISECOND]
                         else
                           [duration_ns / 1_000_000_000, SECOND]
                         end

          number = format(DURATION_FORMAT, number)
                   .gsub(TRAILING_ZERO_RE, "")
                   .delete_suffix(DOT)

          "#{number}#{unit}"
        end
      end
    end
  end
end
