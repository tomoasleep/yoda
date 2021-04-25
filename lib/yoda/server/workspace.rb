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

      # @param root_uri [Array<Project>]
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

      def reparse_doc(uri)
        path = FileStore.path_of_uri(uri)
        return unless subpath?(path)
        project.read_source(path)
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
