require 'concurrent'
require 'forwardable'

module Yoda
  class Server
    class RootHandler
      extend Forwardable

      delegate session: :lifecycle_handler

      # @!method notifier
      #   @return [Notifier]
      delegate notifier: :server_controller

      # @return [ConcurrentWriter]
      attr_reader :writer

      # @return [Scheduler]
      attr_reader :scheduler

      # @return [ServerController]
      attr_reader :server_controller

      # @param writer [ConcurrentWriter]
      # @param scheduler [Scheduler]
      def initialize(writer:, scheduler: nil)
        @scheduler = scheduler || Scheduler.new
        @writer = writer
        @server_controller = ServerController.new(writer: writer, scheduler: scheduler)
      end

      # @param message [Hash]
      def handle(message)
        if message[:method]
          handle_request(id: message[:id], method: message[:method].to_sym, params: message[:params] || {})
        elsif message[:id] && (message[:result] || message[:error])
          handle_response(id: message[:id], result: message[:result], error: message[:error])
        end
      end

      # @param id [String]
      # @param method [Symbol]
      # @param params [Hash]
      # @return [Concurrent::Future, nil]
      def handle_request(id:, method:, params:)
        Logger.trace("Request (#{id}): #{method}(#{params})")
        if lifecycle_handler.handle?(method)
          return write_response(id, lifecycle_handler.handle(method: method, params: params))
        end

        return write_response(id, build_error_response(NotInitializedError.new)) unless session

        if provider = Providers.build_provider(session: session, method: method)
          provide_async(provider: provider, id: id, method: method, params: params)
        else
          if id
            write_response(id, build_error_response(NotImplementedMethod.new(method)))
          else
            Logger.instance.debug("A notification with a not implemented method (#{method}) received")
          end
        end
      end

      # @param id [String]
      # @param method [Symbol]
      # @param params [Hash]
      def handle_response(id:, result:, error:)
        callbacks = server_controller.response_callbacks.take_callbacks(id)
        callbacks.each do |callback|
          async_id = SecureRandom.uuid
          scheduler.async(id: async_id) do
            callback.call(result, error)
          end
        end
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

      def send_request(id:, method:, params:, &callback)
        request_message = LanguageServer::Protocol::Interface::RequestMessage.new(id: id, method: method, params: params)
      end

      private

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
          if reason
            write_response(id, build_error_response(reason))
          else
            write_response(id, value)
          end
        end

        future
      end

      # @param id [Object]
      # @param result [Object]
      # @return [nil]
      def write_response(id, result)
        return if result == NO_RESPONSE
        server_controller.write_response(id: id, result: result)

        nil
      end

      def build_error_response(reason)
        server_controller.build_error_response(reason)
      end
    end
  end
end
