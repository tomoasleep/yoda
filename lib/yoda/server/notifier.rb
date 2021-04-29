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
        start_progress(id: id, title: type)
        yield
      rescue => e
        Logger.warn(e.full_message)
        failed = true
        raise e 
      ensure
        event(type: type, phase: :end, id: id)
        failed ? cancel_progress(id: id) : done_progress(id: id)
      end

      # @param params [Hash]
      def event(params)
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

      # @param id [String, Symbol]
      # @param title [String]
      # @param calcellable [Boolean]
      # @param message [String, nil]
      # @param percentage [Integer]
      def start_progress(id:, title:, cancellable: false, message: nil, percentage: 0)
        write(
          method: 'window/progress/start',
          params: {
            id: id,
            title: title,
            calcellable: cancellable,
            message: message,
            percentage: percentage,
          }
        )
      end

      # @param id [String, Symbol]
      # @param message [String, nil]
      # @param percentage [Integer, nil]
      def report_progress(id:, message: nil, percentage: nil)
        write(
          method: 'window/progress/report',
          params: {
            id: id,
            message: message,
            percentage: percentage,
          }
        )
      end

      # @param id [String, Symbol]
      def done_progress(id:)
        write(
          method: 'window/progress/done',
          params: {
            id: id,
          }
        )
      end

      # @param id [String, Symbol]
      def cancel_progress(id:)
        write(
          method: 'window/progress/cancel',
          params: {
            id: id,
          }
        )
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
