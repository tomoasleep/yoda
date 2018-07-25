module Yoda
  class Server
    class InitializationProvider
      # @return [Session]
      attr_reader :session

      # @param session [Session]
      def initialize(session)
        @session = session
      end

      # @return [LanguageServer::Protocol::Interface::ShowMessageParams, nil]
      def provide
        errors = session.setup
        build_complete_message(errors)
      end

      private

      # @param errors [Array<BaseError>]
      # @return [LanguageServer::Protocol::Interface::ShowMessageParams, nil]
      def build_complete_message(errors)
        return if errors.empty?
        gem_import_errors = errors.select { |error| error.is_a?(GemImportError) }
        core_import_errors = errors.select { |error| error.is_a?(CoreImportError) }

        warnings = gem_import_warnings(gem_import_errors) + core_import_warnings(core_import_errors)
        LanguageServer::Protocol::Interface::ShowMessageParams.new(
          type: LanguageServer::Protocol::Constant::MessageType::WARNING,
          message: "There are some libraries to failed to import (Ruby version: #{RUBY_VERSION})\n" + warnings.join("\n"),
        )
      end

      # @param gem_import_errors [Array<GemImportError>]
      # @return [Array<String>]
      def gem_import_warnings(gem_import_errors)
        gem_import_errors.map { |error| "#{error.name} #{error.version}" }
      end

      # @param gem_import_errors [Array<GemImportError>]
      # @return [Array<String>]
      def core_import_warnings(core_import_errors)
        core_import_errors.map { |error| "#{error.name}" }
      end
    end
  end
end
