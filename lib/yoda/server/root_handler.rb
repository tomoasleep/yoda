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

      # @return [Scheduler]
      attr_reader :scheduler

      # @param writer [ConcurrentWriter]
      # @param scheduler [Scheduler]
      def initialize(writer:, scheduler: nil)
        @scheduler = scheduler || Scheduler.new
        @writer = writer
        @future_map = Concurrent::Map.new
      end

      # @param id [String]
      # @param method [Symbol]
      # @param params [Hash]
      # @return [Concurrent::Future, nil]
      def handle(id:, method:, params:)
        Logger.trace("Request (#{id}): #{method}(#{params})")
        if lifecycle_handler.handle?(method)
          return write_response(id, lifecycle_handler.handle(method: method, params: params))
        end

        return write_response(id, build_error_response(NOT_INITIALIZED)) unless session

        if provider = Providers.build_provider(notifier: notifier, session: session, method: method)
          provide_async(provider: provider, id: id, method: method, params: params)
        else
          if id
            write_response(id, build_error_response(NotImplementedMethod.new(method)))
          else
            Logger.instance.debug("A notification with a not implemented method (#{method}) received")
          end
        end
      end

      # @return [Notifier]
      def notifier
        @notifier ||= Notifier.new(writer)
      end

      # Wait pending requests
      def wait_for_termination(timeout:)
        scheduler.wait_for_termination(timeout: timeout)
      end

      # @param id [String]
      def cancel_request(id)
        scheduler.cancel(id)
      end

      def cancel_all_requests
        scheduler.cancel_all
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
        future = scheduler.async(id: id) do
          notifier.busy(type: method, id: id) { provider.provide(params) }
        end
        future.add_observer do |_time, value, reason|
          reason ? write_response(id, build_error_response(reason)) : write_response(id, value)
        end

        future
      end

      # @param id [Object]
      # @param result [Object]
      # @return [nil]
      def write_response(id, result)
        return if result == NO_RESPONSE
        Logger.trace("Response (#{id}): #{result.to_json}")
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
        when Timeout::Error
          LanguageServer::Protocol::Interface::ResponseError.new(
            code: LanguageServer::Protocol::Constant::ErrorCodes::INTERNAL_ERROR,
            message: 'Requiest timeout',
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
