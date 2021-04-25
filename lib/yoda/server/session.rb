require 'uri'

module Yoda
  class Server
    class Session
      # @return [FileStore]
      attr_reader :file_store

      # @return [Array<Workspace>]
      attr_reader :workspaces

      def self.from_root_uri(root_uri)
        workspaces = [Workspace.new(name: 'root', root_uri: root_uri)]
        new(workspaces: workspaces)
      end

      # @param workspace_folders [Array<LanguageServer::Protocol::Interface::WorkspaceFolder>] an uri expression of project root path
      def self.from_workspace_folders(workspace_folders)
        workspaces = Workspace.new(name: folder.name, root_uri: folder.uri)
        new(workspaces: workspaces)
      end

      # @param workspaces [Array<Workspace>]
      def initialize(workspaces:)
        @file_store = FileStore.new
        @workspaces = workspaces
      end

      # @return [Store::Registry]
      def registry
        project.registry
      end

      def setup
        unless Store::Actions::BuildCoreIndex.exists?
          Instrument.instance.initialization_progress(phase: :core, message: 'Downloading and building core index')
          Store::Actions::BuildCoreIndex.run
        end
        workspaces.each(&:setup)
      end

      # @return [Store::Project, nil]
      def project
        workspaces.first&.project
      end

      def reparse_doc(uri)
        workspaces.each { |workspace| workspace.reparse_doc(uri) }
      end
    end
  end
end
