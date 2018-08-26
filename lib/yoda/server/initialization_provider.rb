module Yoda
  class Server
    class InitializationProvider
      # @return [Session]
      attr_reader :session

      # @return [Notifier]
      attr_reader :notifier

      # @param session [Session]
      # @param nofitier [Notifier]
      def initialize(session:, notifier:)
        @session = session
        @notifier = notifier
      end

      # @return [LanguageServer::Protocol::Interface::ShowMessageParams, nil]
      def provide
        errors = Instrument.instance.hear(initialization_progress: method(:notify_initialization_progress)) do
          session.setup
        end
        build_complete_message(errors)
      end

      private

      # @param errors [Array<BaseError>]
      # @return [Array<Object>]
      def build_complete_message(errors)
        return [] if errors.empty?
        gem_import_errors = errors.select { |error| error.is_a?(GemImportError) }
        core_import_errors = errors.select { |error| error.is_a?(CoreImportError) }

        notifications = [
          {
            method: 'window/showMessage',
            params: LanguageServer::Protocol::Interface::ShowMessageParams.new(
              type: LanguageServer::Protocol::Constant::MessageType::WARNING,
              message: "Failed to load some libraries (Please check console for details)",
            )
          }
        ]

        if gem_message = gem_import_warnings(gem_import_errors)
          notifications.push(
            method: 'window/logMessage',
            params: LanguageServer::Protocol::Interface::LogMessageParams.new(
              type: LanguageServer::Protocol::Constant::MessageType::WARNING,
              message: gem_message,
            ),
          )
        end

        if core_message = core_import_warnings(core_import_errors)
          notifications.push(
            method: 'window/logMessage',
            params: LanguageServer::Protocol::Interface::LogMessageParams.new(
              type: LanguageServer::Protocol::Constant::MessageType::WARNING,
              message: core_message,
            ),
          )
        end

        notifications
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
