module Sneakers
  module Metrics
    class NullMetrics
      def increment(metric)
      end

      def timing(metric, &block)
        block.call
      end

      def gauge(metric, value)
      end
    end
  end
end

