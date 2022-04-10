require 'uri'

module Yoda
  class Server
    class Session
      # @return [Array<Workspace>]
      attr_reader :workspaces

      def self.from_root_uri(root_uri)
        workspaces = [Workspace.new(name: 'root', root_uri: root_uri)]
        Logger.trace("Setting up session for #{root_uri}")
        new(workspaces: workspaces)
      end

      # @param workspace_folders [Array<LanguageServer::Protocol::Interface::WorkspaceFolder>] an uri expression of project root path
      def self.from_workspace_folders(workspace_folders)
        workspaces = workspace_folders.map { |folder| Workspace.from_workspace_folder(folder) }
        new(workspaces: workspaces)
      end

      # @param workspaces [Array<Workspace>]
      def initialize(workspaces:)
        @workspaces = workspaces
      end

      # @return [Store::Registry]
      def registry
        project.registry
      end

      # @param controller [Server::ServerController, nil]
      def setup(controller: nil)
        workspaces.map { |workspace| workspace.setup(controller: controller) }
      end

      # @param new_workspace [Workspace]
      def add_workspace(new_workspace)
        return if workspaces.find { |workspace| workspace.id == new_workspace.id }
        new_workspace.setup
        workspaces.push(new_workspace)
      end

      # @param id [String]
      def remove_workspace(id:)
        @workspaces = workspaces.reject { |workspace| workspace.id == id }
      end

      # @return [Store::Project, nil]
      def project
        workspaces.first&.project
      end

      def read_source(uri)
        workspaces_for(uri).each { |workspace| workspace.read_source(uri) }
      end
      alias reparse_doc read_source

      # @param uri [String]
      # @param source [String]
      def store_source(uri:, source:)
        workspaces_for(uri).each { |workspace| workspace.store_source(uri: uri, source: source) }
      end

      # @param uri [String]
      def remove_source(uri:)
        workspaces_for(uri).each { |workspace| workspace.remove_source(uri: uri) }
      end

      # @return [Workspace, nil]
      def workspace_for(uri)
        workspaces_for(uri).first
      end

      # @return [Array<Workspace>]
      def workspaces_for(uri)
        matched_workspaces = workspaces.select { |workspace| workspace.suburi?(uri) }
        matched_workspaces.empty? ? [temporal_workspace_for(uri)] : matched_workspaces
      end

      def temporal_workspace_for(uri)
        temporal_workspaces[uri] ||= RootlessWorkspace.new(name: uri).tap do |workspace|
          Logger.trace "Setting up temporal workspace for #{uri}"
          workspace.setup
          # Store the file content to the temporally workspace
          workspace.read_source(uri)
        end
      end

      private

      def temporal_workspaces
        @temporal_workspaces ||= {}
      end
    end
  end
end
