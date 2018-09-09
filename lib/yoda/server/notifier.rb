module Yoda
  class Server
    class Notifier
      # @param writer [ConcurrentWriter]
      def initialize(writer)
        @writer = writer
      end

      # @param type [Symbol]
      def busy(type:)
        event(type: type, phase: :begin)
        yield
      ensure
        event(type: type, phase: :end)
      end

      # @param params [Hash]
      def event(params)
        write(method: 'telemetry/event', params: params)
      end

      # @param type [String, Symbol]
      # @param message [String]
      def show_message(type:, message:)
        write(
          method: 'window/showMessage',
          params: LanguageServer::Protocol::Interface::ShowMessageParams.new(
            type: message_type(type),
            message: message,
          )
        )
      end

      # @param type [String, Symbol]
      # @param message [String]
      def log_message(type:, message:)
        write(
          method: 'window/logMessage',
          params: LanguageServer::Protocol::Interface::ShowMessageParams.new(
            type: message_type(type),
            message: message,
          )
        )
      end

      private

      def write(params)
        @writer.write(params)
      end

      # @param type [String, Symbol]
      def message_type(type)
        case type.to_sym
        when :error
          LanguageServer::Protocol::Constant::MessageType::ERROR
        when :warning
          LanguageServer::Protocol::Constant::MessageType::WARNING
        when :info
          LanguageServer::Protocol::Constant::MessageType::INFO
        when :log
          LanguageServer::Protocol::Constant::MessageType::LOG
        else
          Logger.warn("#{type} is not valie message type")
          LanguageServer::Protocol::Constant::MessageType::INFO
        end
      end

      # @return [Server]
      attr_reader :server
    end
  end
end
