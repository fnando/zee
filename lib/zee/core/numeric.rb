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

        # @!method second
        # Returns the number of seconds.
        # @return [Numeric] the number of seconds.
        def second
          self
        end
        alias_method :seconds, :second

        # @!method minute
        # Returns the number of minutes in seconds.
        # @return [Numeric] the number of seconds.
        def minute
          self * 60
        end
        alias_method :minutes, :minute

        # @!method hour
        # Returns the number of hours in seconds.
        # @return [Numeric] the number of seconds.
        def hour
          self * 3600
        end
        alias_method :hours, :hour

        # @!method day
        # Returns the number of days in seconds.
        # @return [Numeric] the number of seconds.
        def day
          self * 86_400
        end
        alias_method :days, :day

        # @!method week
        # Returns the number of weeks in seconds.
        # @return [Numeric] the number of seconds.
        def week
          self * 86_400 * 7
        end
        alias_method :weeks, :week

        # @!method month
        # Returns the number of months in seconds.
        # A month is considered to be 1/12 of a gregorian year, to match Rails'
        # behavior.
        #
        # @return [Numeric] the number of seconds.
        def month
          self * 2_629_746
        end
        alias_method :months, :month

        # @!method year
        # Returns the number of years in seconds.
        # A year is considered to be a full gregorian year (365.2425 days), to
        # match Rails' behavior.
        #
        # @return [Numeric] the number of seconds.
        def year
          self * 31_556_952
        end
        alias_method :years, :year
      end
    end
  end
end
