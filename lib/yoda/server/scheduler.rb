require 'concurrent'

module Yoda
  class Server
    class Scheduler
      # @return [Concurrent::ThreadPoolExecutor]
      attr_reader :thread_pool

      # @return [Concurrent::Map{String => Concurrent::Future}]
      attr_reader :future_map

      # @return [Concurrent::ThreadPoolExecutor]
      def self.default_thread_pool
        Concurrent.global_fast_executor
      end

      # @param thread_pool [Concurrent::ThreadPoolExecutor]
      def initialize(thread_pool: nil)
        @thread_pool = thread_pool || self.class.default_thread_pool
        @future_map = Concurrent::Map.new
      end

      # @param id [String]
      # @return [Concurrent::Future]
      def async(id:, &block)
        future = Concurrent::Future.new(executor: thread_pool) { block.call }
        future.add_observer { |_time, value, reason| future_map.delete(id) }
        future_map.put_if_absent(id, future)
        future.execute
        future
      end

      # @param id [String]
      def cancel(id)
        future_map[id]&.cancel
      end

      # @param timeout [Integer] the maximum number of seconds to wait for shutdown to complete.
      def wait_for_termination(timeout:)
        thread_pool.shutdown
        thread_pool.wait_for_termination(timeout)
      end

      def cancel_all
        future_map.each_value { |future| future&.cancel }
      end
    end
  end
end

