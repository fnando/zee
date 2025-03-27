# frozen_string_literal: true

module Zee
  module CLI
    class Root < Command
      desc "dev", "Start the dev server (requires ./bin/dev)"
      # :nocov:
      def dev
        pid = Process.spawn("./bin/dev")
        signals = %w[INT]

        signals.each do |signal|
          Signal.trap(signal) do
            Process.kill(signal, pid)
          rescue Errno::ESRCH
            # Process already gone
          end
        rescue ArgumentError
          # Skip signals that can't be trapped
        end

        Process.wait(pid)
      end
      # :nocov:
    end
  end
end
