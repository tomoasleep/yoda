require 'concurrent'

module Yoda
  class Server
    # Handle
    class LifecycleHandler
      # @return [Session, nil]
      attr_reader :session

      # @return [Notifier]
      attr_reader :notifier

      def initialize(root_handler)
        @root_handler = root_handler
        @notifier = root_handler.notifier
      end

      # @param method [Symbol]
      # @return [true, false]
      def handle?(method)
        lifecycle_handlers.key?(method)
      end

      # @param method [Symbol]
      # @param params [Object]
      def handle(method:, params:)
        lifecycle_handlers[method].call(params)
      end

      private

      def lifecycle_handlers
        @lifecycle_handlers ||= {
          initialize: method(:handle_initialize),
          initialized: method(:handle_initialized),
          shutdown: method(:handle_shutdown),
          exit: method(:handle_exit),
          '$/cancelRequest': method(:handle_cancel),
        }
      end

      def handle_initialize(params)
        Instrument.instance.hear(initialization_progress: method(:notify_initialization_progress)) do
          @session = Session.new(params[:root_uri])
          send_warnings(@session.setup || [])

          LanguageServer::Protocol::Interface::InitializeResult.new(
            capabilities: LanguageServer::Protocol::Interface::ServerCapabilities.new(
              text_document_sync: LanguageServer::Protocol::Interface::TextDocumentSyncOptions.new(
                change: LanguageServer::Protocol::Constant::TextDocumentSyncKind::FULL,
                save: LanguageServer::Protocol::Interface::SaveOptions.new(
                  include_text: true,
                ),
              ),
              completion_provider: LanguageServer::Protocol::Interface::CompletionOptions.new(
                resolve_provider: false,
                trigger_characters: ['.', '@', '[', ':', '!', '<'],
              ),
              hover_provider: true,
              definition_provider: true,
              signature_help_provider: LanguageServer::Protocol::Interface::SignatureHelpOptions.new(
                trigger_characters: ['(', ','],
              ),
            ),
          )
        end
      rescue => e
        LanguageServer::Protocol::Interface::ResponseError.new(
          message: "Failed to initialize yoda: #{e.class} #{e.message}",
          code: LanguageServer::Protocol::Constant::ErrorCodes::SERVER_ERROR_START,
          data: LanguageServer::Protocol::Interface::InitializeError.new(retry: false),
        )
      end

      def handle_initialized(_params)
        NO_RESPONSE
      end

      def handle_shutdown(_params)
      end

      def handle_cancel(params)
        @root_handler.cancel_request(params[:id])

        NO_RESPONSE
      end

      def handle_exit(_params)
        NO_RESPONSE
      end

      # @param errors [Array<BaseError>]
      # @return [Array<Object>]
      def send_warnings(errors)
        return [] if errors.empty?
        gem_import_errors = errors.select { |error| error.is_a?(GemImportError) }
        core_import_errors = errors.select { |error| error.is_a?(CoreImportError) }

        notifier.show_message(
          type: :warning,
          message: "Failed to load some libraries (Please check console for details)",
        )

        if gem_message = gem_import_warnings(gem_import_errors)
          notifier.log_message(
            type: :warning,
            message: gem_message,
          )
        end

        if core_message = core_import_warnings(core_import_errors)
          notifier.log_message(
            type: :warning,
            message: core_message,
          )
        end
      end

      # @param gem_import_errors [Array<GemImportError>]
      # @return [String, nil]
      def gem_import_warnings(gem_import_errors)
        return if gem_import_errors.empty?
        warnings = gem_import_errors.map { |error| "- #{error.name} (#{error.version})" }

        <<~EOS
        Failed to import some gems.
        Please check these gems are installed for Ruby version #{RUBY_VERSION}.
        #{warnings.join("\n")}
        EOS
      end

      # @param gem_import_errors [Array<GemImportError>]
      # @return [String, nil]
      def core_import_warnings(core_import_errors)
        return if core_import_errors.empty?

        <<~EOS
        Failed to import some core libraries (Ruby version: #{RUBY_VERSION}).
        Please execute `yoda setup` with Ruby version #{RUBY_VERSION}.
        EOS
      end

      def notify_initialization_progress(phase: nil, message: nil, **params)
        notifier.event(type: :initialization, phase: phase, message: message)
      end
    end
  end
end
