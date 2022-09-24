module Yoda
  class Server
    class Notifier
      # @param writer [ConcurrentWriter]
      def initialize(writer)
        @writer = writer
      end

      # @param type [Symbol]
      def busy(type:, id: nil)
        failed = false
        event(type: type, phase: :begin, id: id)
        yield
      rescue => e
        Logger.warn(e.full_message)
        failed = true
        event(type: type, phage: :failed, id: id, reason: e.message, detailed_reason: e.full_message)
        raise e
      ensure
        event(type: type, phase: :end, id: id)
      end

      # @param id [Object]
      # @param result [Object]
      # @return [void]
      def write_response(id:, result:)
        Logger.trace("Response (#{id}): #{result.to_json}")
        if result.is_a?(LanguageServer::Protocol::Interface::ResponseError)
          write(id: id, error: result)
        else
          write(id: id, result: result)
        end

        nil
      end

      # @param id [Object]
      # @param method [Object]
      # @param params [Object]
      def write_request(method:, params:, id: nil)
        write(id: id, method: method, params: params)
      end

      # @param params [Hash]
      def event(**params)
        write(method: 'telemetry/event', params: params)
      end

      # @param token [Integer, String]
      # @param title [String]
      # @param cancellable [Boolean, nil]
      # @param message [String]
      # @param percentage [Integer]
      # @see https://microsoft.github.io/language-server-protocol/specifications/specification-current/#workDoneProgressBegin
      def work_done_progress_begin(token:, title:, cancellable: nil, message: nil, percentage: nil)
        write(
          method: '$/progress',
          params: LanguageServer::Protocol::Interface::ProgressParams.new(
            token: token,
            value: LanguageServer::Protocol::Interface::WorkDoneProgressBegin.new(
              kind: "begin",
              title: title,
              cancellable: cancellable,
              message: message,
              percentage: percentage,
            )
          ),
        )
      end

      # @param token [Integer, String]
      # @param cancellable [Boolean, nil]
      # @param message [String]
      # @param percentage [Integer]
      # @see https://microsoft.github.io/language-server-protocol/specifications/specification-current/#workDoneProgressReport
      def work_done_progress_report(token:, cancellable: nil, message: nil, percentage: nil)
        write(
          method: '$/progress',
          params: LanguageServer::Protocol::Interface::ProgressParams.new(
            token: token,
            value: LanguageServer::Protocol::Interface::WorkDoneProgressReport.new(
              kind: "report",
              cancellable: cancellable,
              message: message,
              percentage: percentage,
            )
          ),
        )
      end

      # @param token [Integer, String]
      # @param message [String]
      # @see https://microsoft.github.io/language-server-protocol/specifications/specification-current/#workDoneProgressEnd
      def work_done_progress_end(token:, message: nil)
        write(
          method: '$/progress',
          params: LanguageServer::Protocol::Interface::ProgressParams.new(
            token: token,
            value: LanguageServer::Protocol::Interface::WorkDoneProgressEnd.new(
              kind: "end",
              message: message,
            )
          ),
        )
      end

      # @param token [String]
      def create_work_done_progress(id:, token:)
        write(
          id: id,
          method: 'window/workDoneProgress/create',
          params: LanguageServer::Protocol::Interface::WorkDoneProgressCreateParams.new(
            token: token,
          ),
        )
      end

      # @param token [String]
      def cancel_work_done_progress(token:)
        write(
          method: 'window/workDoneProgress/cancel',
          params: LanguageServer::Protocol::Interface::WorkDoneProgressCancelParams.new(
            token: token,
          ),
        )
      end

      # @param token [Integer, String]
      # @param value [Object] The partial result to send. In most cases, the type of this becomes the result type of the request.
      # @see https://microsoft.github.io/language-server-protocol/specifications/specification-current/#partialResults
      def partial_result(token:, value:)
        write(
          method: '$/progress',
          params: LanguageServer::Protocol::Interface::ProgressParams.new(
            token: token,
            value: value,
          ),
        )
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

      # @param reason [Exception, Symbol, Struct]
      # @return [LanguageServer::Protocol::Interface::ResponseError]
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
        when NotInitializedError
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

      # @param registrations [Array<Registration>]
      def register_capability(registrations)
        id = SecureRandom.uuid
        write_request(id: id, method: 'client/registerCapability', params: registrations)
      end

      private

      def write(params)
        Logger.trace("Notify: #{params}")
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
