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

      # @param params [LanguageServer::Protocol::Interface::InitializeParams]
      def handle_initialize(params)
        Instrument.instance.hear(initialization_progress: method(:notify_initialization_progress)) do
          @session = begin
            if params[:workspace_folders]
              workspace_folders = params[:workspace_folders].map { |hash| LanguageServer::Protocol::Interface::WorkspaceFolder.new(name: hash[:name], uri: hash[:uri]) }
              Session.from_workspace_folders(workspace_folders)
            elsif params[:root_uri]
              Session.from_root_uri(params[:root_uri])
            else
              Session.new(workspaces: [])
            end
          end

          send_warnings(@session.setup || [])

          LanguageServer::Protocol::Interface::InitializeResult.new(
            server_info: {
              name: "yoda",
              version: Yoda::VERSION,
            },
            capabilities: LanguageServer::Protocol::Interface::ServerCapabilities.new(
              text_document_sync: LanguageServer::Protocol::Interface::TextDocumentSyncOptions.new(
                open_close: true,
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
              workspace_symbol_provider: LanguageServer::Protocol::Interface::WorkspaceSymbolOptions.new(
                work_done_progress: true,
              ),
              workspace: {
                workspaceFolders: LanguageServer::Protocol::Interface::WorkspaceFoldersServerCapabilities.new(
                  supported: true,
                  change_notifications: true,
                ),
              },
            ),
          )
        end
      rescue => e
        Logger.warn e.full_message
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
          message: warning_summary(core_import_errors, gem_import_errors),
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

      def warning_summary(core_import_errors, gem_import_errors)
        error_list = []
        error_list += ["- core library"] unless core_import_errors.empty?
        error_list += gem_import_errors.map { |error| "- #{error.name} (#{error.version})" }

        <<~EOS
        Failed to load some libraries
        #{error_list.join("\n")}
        EOS
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

      def notify_initialization_progress(phase: nil, message: nil, index:, length:)
        if length && length > 0
          percentage = (index || 0) * 100 / length
          if index <= 0
            notifier.start_progress(id: phase, title: phase, message: message, percentage: percentage)
          elsif index >= length
            notifier.done_progress(id: phase)
          else
            notifier.report_progress(id: phase, message: message, percentage: percentage)
          end
        else
          notifier.event(type: :initialization, phase: phase, message: message)
        end
      end
    end
  end
end
