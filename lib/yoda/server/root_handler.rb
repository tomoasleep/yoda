require 'concurrent'
require 'forwardable'

module Yoda
  class Server
    class RootHandler
      extend Forwardable
      NOT_INITIALIZED = :not_initialized
      NotImplementedMethod = Struct.new(:method_name)

      delegate session: :lifecycle_handler

      # @return [ConcurrentWriter]
      attr_reader :writer

      # @return [Concurrent::ThreadPoolExecutor]
      attr_reader :thread_pool

      # @return [Concurrent::ThreadPoolExecutor]
      def self.default_thread_pool
        Concurrent.global_fast_executor
      end

      # @param writer [ConcurrentWriter]
      # @param thread_pool [Concurrent::ThreadPoolExecutor]
      def initialize(writer:, thread_pool: nil)
        @thread_pool = thread_pool || self.class.default_thread_pool
        @writer = writer
        @future_map = Concurrent::Map.new
      end

      # @param id [String]
      # @param method [Symbol]
      # @param params [Hash]
      # @return [Concurrent::Future, nil]
      def handle(id:, method:, params:)
        if lifecycle_handler.handle?(method)
          return write_response(id, lifecycle_handler.handle(method: method, params: params))
        end

        return write_response(id, build_error_response(NOT_INITIALIZED)) unless session

        if provider = Providers.build_provider(notifier: notifier, session: session, method: method)
          provide_async(provider: provider, id: id, method: method, params: params)
        else
          write_response(id, build_error_response(NotImplementedMethod.new(method)))
        end
      end

      # @return [Notifier]
      def notifier
        @notifier ||= Notifier.new(writer)
      end

      # @param id [String]
      def cancel_request(id)
        future_map[id]&.cancel
      end

      def cancel_all_requests
        future_map.each_value { |future| future&.cancel }
      end

      private

      # @return [Concurrent::Map{ String => Future }]
      attr_reader :future_map

      # @return [LifecycleHandler]
      def lifecycle_handler
        @lifecycle_handler ||= LifecycleHandler.new(self)
      end

      # @return [Concurrent::Future]
      def provide_async(provider:, id:, method:, params:)
        future = Concurrent::Future.new(executor: thread_pool) do
          notifier.busy(type: method, id: id) { provider.provide(params) }
        end
        future.add_observer do |_time, value, reason|
          begin
            reason ? write_response(id, build_error_response(reason)) : write_response(id, value)
          ensure
            future_map.delete(id)
          end
        end
        future_map.put_if_absent(id, future)
        Concurrent::ScheduledTask.execute(provider.timeout, executor: thread_pool) { future.cancel } if provider.timeout
        
        future.execute
        future
      end

      # @param id [Object]
      # @param result [Object]
      # @return [nil]
      def write_response(id, result)
        return if result == NO_RESPONSE
        if result.is_a?(LanguageServer::Protocol::Interface::ResponseError)
          writer.write(id: id, error: result)
        else
          writer.write(id: id, result: result)
        end

        nil
      end

      # @param reason [Exception, Symbol, Struct]
      def build_error_response(reason)
        case reason
        when Concurrent::CancelledOperationError
          LanguageServer::Protocol::Interface::ResponseError.new(
            code: LanguageServer::Protocol::Constant::ErrorCodes::REQUEST_CANCELLED,
            message: 'Request is canceled',
          )
        when NOT_INITIALIZED
          LanguageServer::Protocol::Interface::ResponseError.new(
            code: LanguageServer::Protocol::Constant::ErrorCodes::SERVER_NOT_INITIALIZED,
            message: "Server is not initialized",
          )
        when NotImplementedMethod
          LanguageServer::Protocol::Interface::ResponseError.new(
            code: LanguageServer::Protocol::Constant::ErrorCodes::METHOD_NOT_FOUND,
            message: "Method (#{reason.method_name}) is not implemented",
          )
        else
          LanguageServer::Protocol::Interface::ResponseError.new(
            code: LanguageServer::Protocol::Constant::ErrorCodes::INTERNAL_ERROR,
            message: reason.respond_to?(:message) ? message : 'Internal error',
          )
        end
      end
    end
  end
end
