require 'language_server-protocol'

module Yoda
  class Server
    require 'yoda/server/completion_provider'
    require 'yoda/server/signature_provider'
    require 'yoda/server/hover_provider'
    require 'yoda/server/reference_provider'
    require 'yoda/server/deserializer'
    require 'yoda/server/client_info'

    LSP = ::LanguageServer::Protocol

    def self.deserialize(hash)
      Deserializer.new.deserialize(hash || {})
    end

    attr_reader :reader, :writer, :client_info, :completion_provider, :hover_provider, :signature_provider, :reference_provider
    def initialize
      @reader = LSP::Transport::Stdio::Reader.new
      @writer = LSP::Transport::Stdio::Writer.new
    end

    def run
      reader.read do |request|
        begin
          if result = callback(request)
            writer.write(id: request[:id], result: result)
          end
        rescue StandardError => ex
          STDERR.puts ex
          STDERR.puts ex.backtrace
        end
      end
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
    def resolve(hash, key)
      key.to_s.split('/').reduce(hash) do |scope, key|
        (scope || {})[key.to_sym]
      end
    end

    def request_registrations
      {
        initialize: :handle_initialize,
        shutdown: :handle_shutdown,
        textDocument: {
          completion: :handle_text_document_completion,
          hover: :handle_text_document_hover,
          signatureHelp: :handle_text_document_signature_help,
          references: :handle_text_document_references,
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
      @client_info = ClientInfo.new(params[:root_uri])
      @completion_provider = CompletionProvider.new(@client_info)
      @hover_provider = HoverProvider.new(@client_info)
      @signature_provider = SignatureProvider.new(@client_info)
      @reference_provider = ReferenceProvider.new(@client_info)

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
            trigger_characters: ['.'],
          ),
          hover_provider: true,
          references_provider: true,
          signature_help_provider: LSP::Interface::SignatureHelpOptions.new(
            trigger_characters: ['(', ','],
          ),
        ),
      )
    end

    def handle_initialized(_params)
      client_info.setup
    end

    def handle_shutdown(_params)
    end

    def handle_exit(_params)
    end

    module TextDocument
      module CompletionTrigggerKind
        Invoked = 1
        TriggerCharacter = 2
      end

      def handle_text_document_did_open(params)
        uri = params[:text_document][:uri]
        text = params[:text_document][:text]
        client_info.file_store.store(uri, text)
      end

      def handle_text_document_did_save(params)
        uri = params[:text_document][:uri]

        client_info.reparse_doc(uri)
      end

      def handle_text_document_did_change(params)
        uri = params[:text_document][:uri]
        text = params[:content_changes].first[:text]
        client_info.file_store.store(uri, text)
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

      def handle_text_document_references(params)
        uri = params[:text_document][:uri]
        position = params[:position]

        reference_provider&.provide(uri, position)
      end
    end
    include TextDocument
  end
end
