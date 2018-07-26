require 'language_server-protocol'
require 'securerandom'

module Yoda
  class Server
    require 'yoda/server/completion_provider'
    require 'yoda/server/signature_provider'
    require 'yoda/server/hover_provider'
    require 'yoda/server/definition_provider'
    require 'yoda/server/initialization_provider'
    require 'yoda/server/deserializer'
    require 'yoda/server/session'

    LSP = ::LanguageServer::Protocol

    def self.deserialize(hash)
      Deserializer.new.deserialize(hash || {})
    end

    # @type ::LanguageServer::Protocol::Transport::Stdio::Reader
    attr_reader :reader

    # @type ::LanguageServer::Protocol::Transport::Stdio::Writer
    attr_reader :writer

    # @return [Responser]
    attr_reader :session

    # @type CompletionProvider
    attr_reader :completion_provider

    # @type HoverProvider
    attr_reader :hover_provider

    # @type SignatureProvider
    attr_reader :signature_provider

    # @type DefinitionProvider
    attr_reader :definition_provider

    # @return [Array<Hash>]
    attr_reader :after_notifications

    def initialize
      @reader = LSP::Transport::Stdio::Reader.new
      @writer = LSP::Transport::Stdio::Writer.new
      @after_notifications = []
    end

    def run
      reader.read do |request|
        begin
          if result = callback(request)
            writer.write(id: request[:id], result: result)
          end
          process_after_notifications if session&.client_initialized
        rescue StandardError => ex
          STDERR.puts ex
          STDERR.puts ex.backtrace
        end
      end
    end

    def process_after_notifications
      while notification = after_notifications.pop
        send_notification(**notification)
      end
    end

    # @param method [String]
    # @param params [Object]
    def send_notification(method:, params:)
      writer.write(method: method, params: params)
    end

    def callback(request)
      if method_name = resolve(request_registrations, request[:method])
        send(method_name, self.class.deserialize(request[:params] || {}))
      elsif method_name = resolve(notification_registrations, request[:method])
        send(method_name, self.class.deserialize(request[:params] || {}))
        nil
      end
    end

    # @param hash [Hash]
    # @param key [String, Symbol]
    # @return [Symbol, nil]
    def resolve(hash, key)
      resolved = key.to_s.split('/').reduce(hash) do |scope, key|
        (scope || {})[key.to_sym]
      end
      resolved.is_a?(Symbol) && resolved
    end

    def request_registrations
      {
        initialize: :handle_initialize,
        shutdown: :handle_shutdown,
        textDocument: {
          completion: :handle_text_document_completion,
          hover: :handle_text_document_hover,
          signatureHelp: :handle_text_document_signature_help,
          definition: :handle_text_document_definition,
        },
      }
    end

    def notification_registrations
      {
        initialized: :handle_initialized,
        exit: :handle_exit,
        textDocument: {
          didChange: :handle_text_document_did_change,
          didOpen: :handle_text_document_did_open,
          didSave: :handle_text_document_did_save,
        },
      }
    end

    def handle_initialize(params)
      @session = Session.new(params[:root_uri])
      @completion_provider = CompletionProvider.new(@session)
      @hover_provider = HoverProvider.new(@session)
      @signature_provider = SignatureProvider.new(@session)
      @definition_provider = DefinitionProvider.new(@session)

      (InitializationProvider.new(@session).provide || []).each { |notification| after_notifications.push(notification) }

      LSP::Interface::InitializeResult.new(
        capabilities: LSP::Interface::ServerCapabilities.new(
          text_document_sync: LSP::Interface::TextDocumentSyncOptions.new(
            change: LSP::Constant::TextDocumentSyncKind::FULL,
            save: LSP::Interface::SaveOptions.new(
              include_text: true,
            ),
          ),
          completion_provider: LSP::Interface::CompletionOptions.new(
            resolve_provider: true,
            trigger_characters: ['.', '@', '[', ':', '!', '<'],
          ),
          hover_provider: true,
          definition_provider: true,
          signature_help_provider: LSP::Interface::SignatureHelpOptions.new(
            trigger_characters: ['(', ','],
          ),
        ),
      )
    end

    def handle_initialized(_params)
      session.client_initialized = true
    end

    def handle_shutdown(_params)
    end

    def handle_exit(_params)
    end

    module TextDocument
      module CompletionTrigggerKind
        INVOKED = 1
        TRIGGER_CHARACTER = 2
      end

      def handle_text_document_did_open(params)
        uri = params[:text_document][:uri]
        text = params[:text_document][:text]
        session.file_store.store(uri, text)
      end

      def handle_text_document_did_save(params)
        uri = params[:text_document][:uri]

        session.reparse_doc(uri)
      end

      def handle_text_document_did_change(params)
        uri = params[:text_document][:uri]
        text = params[:content_changes].first[:text]
        session.file_store.store(uri, text)
      end

      def handle_text_document_completion(params)
        uri = params[:text_document][:uri]
        position = params[:position]

        completion_provider&.complete(uri, position)
      end

      def handle_text_document_hover(params)
        uri = params[:text_document][:uri]
        position = params[:position]

        hover_provider&.request_hover(uri, position)
      end

      def handle_text_document_signature_help(params)
        uri = params[:text_document][:uri]
        position = params[:position]

        signature_provider&.provide(uri, position)
      end

      def handle_text_document_definition(params)
        uri = params[:text_document][:uri]
        position = params[:position]

        definition_provider&.provide(uri, position)
      end
    end
    include TextDocument
  end
end
