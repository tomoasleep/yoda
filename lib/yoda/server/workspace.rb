require 'uri'

module Yoda
  class Server
    # Denotes workspace folder in LSP.
    # @see: https://microsoft.github.io/language-server-protocol/specifications/specification-current/#workspace_workspaceFolders
    class Workspace
      # @return [FileStore]
      attr_reader :file_store

      # @return [String]
      attr_reader :name

      # @return [String]
      attr_reader :root_uri

      # @param folder [LanguageServer::Protocol::Interface::WorkspaceFolder]
      # @return [Workspace]
      def self.from_workspace_folder(folder)
        new(name: folder.name, root_uri: folder.uri)
      end

      # @param name [String]
      # @param root_uri [String]
      def initialize(name:, root_uri:)
        @name = name
        @root_uri = root_uri
        @file_store = FileStore.new
      end

      def setup
        project.setup
      end

      # @return [Store::Project, nil]
      def project
        @project ||= Store::Project.new(name: name, root_path: root_path)
      end

      def root_path
        FileStore.path_of_uri(root_uri)
      end

      # @param path [String]
      def uri_of_path(path)
        FileStore.uri_of_path(File.expand_path(path, root_path))
      end

      def read_source(uri)
        path = FileStore.path_of_uri(uri)
        return unless subpath?(path)
        file_store.load(uri)
        project.read_source(path)
      end

      # @param uri [String]
      # @param source [String]
      def store_source(uri:, source:)
        file_store.store(uri, source)
      end

      def suburi?(uri)
        path = FileStore.path_of_uri(uri)
        subpath?(path)
      end

      def subpath?(path)
        File.fnmatch("#{root_path}/**/*", path)
      end
    end
  end
end
