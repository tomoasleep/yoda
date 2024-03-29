module Yoda
  class Server
    module Providers
      require 'yoda/server/providers/base'
      require 'yoda/server/providers/with_timeout'
      require 'yoda/server/providers/reportable_progress'

      require 'yoda/server/providers/completion'
      require 'yoda/server/providers/signature'
      require 'yoda/server/providers/hover'
      require 'yoda/server/providers/definition'
      require 'yoda/server/providers/diagnosable'
      require 'yoda/server/providers/text_document_did_change'
      require 'yoda/server/providers/text_document_did_open'
      require 'yoda/server/providers/text_document_did_save'
      require 'yoda/server/providers/workspace_did_change_configuration'
      require 'yoda/server/providers/workspace_did_change_watched_files'
      require 'yoda/server/providers/workspace_did_change_workspace_folders'
      require 'yoda/server/providers/workspace_did_create_files'
      require 'yoda/server/providers/workspace_did_delete_files'
      require 'yoda/server/providers/workspace_did_rename_files'
      require 'yoda/server/providers/workspace_symbol'

      CLASSES = [
        Completion,
        Definition,
        Hover,
        Signature,
        TextDocumentDidChange,
        TextDocumentDidOpen,
        TextDocumentDidSave,
        WorkspaceDidChangeConfiguration,
        WorkspaceDidChangeWatchedFiles,
        WorkspaceDidChangeWorkspaceFolders,
        WorkspaceDidCreateFiles,
        WorkspaceDidDeleteFiles,
        WorkspaceDidRenameFiles,
        WorkspaceSymbol,
      ].freeze

      class << self
        # @param method [Symbol]
        # @param session [Session]
        # @return [Class<Providers::Base>, nil]
        def build_provider(method:, session:)
          find_provider_class(method)&.new(session: session)
        end

        # @param method [Symbol]
        # @return [Class<Providers::Base>, nil]
        def find_provider_class(method)
          CLASSES.find { |provider_class| provider_class.provide?(method) }
        end
      end
    end
  end
end
