require 'uri'
require 'forwardable'

module Yoda
  class Server
    # Denotes workspace folder in LSP.
    # @see: https://microsoft.github.io/language-server-protocol/specifications/specification-current/#workspace_workspaceFolders
    class Workspace
      extend Forwardable

      # @return [String]
      attr_reader :name

      # @return [String]
      attr_reader :root_uri

      delegate [:subpath?] => :file_tree

      delegate [:uri_of_path] => :uri_encoder

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
      end

      # @param scheduler [Server::Scheduler, nil]
      # @return [Array<Exception>] errors on setup
      def setup(scheduler: nil)
        project.setup(scheduler: scheduler)
      end

      # @return [Store::Project, nil]
      def project
        @project ||= Store::Project.for_path(root_path)
      end

      # @return [String]
      def root_path
        UriDecoder.path_of_uri(root_uri)
      end

      # @param uri [String]
      # @return [String, nil]
      def read_at(uri)
        path = UriDecoder.path_of_uri(uri)
        path && file_tree.read_at(path)
      end

      # @param uri [String]
      def read_source(uri)
        path = UriDecoder.path_of_uri(uri)
        return if !path || !program_file?(path)
        file_tree.clear_editing_at(path)
      end

      # @param uri [String]
      # @param source [String]
      def store_source(uri:, source:)
        path = UriDecoder.path_of_uri(uri)
        return if !path || !program_file?(path)
        file_tree.set_editing_at(path, source)
      end

      # @param uri [String]
      def remove_source(uri:)
        path = UriDecoder.path_of_uri(uri)
        file_tree.mark_deleted(path)
      end

      def suburi?(uri)
        path = UriDecoder.path_of_uri(uri)
        path && subpath?(path)
      end

      private

      # @return [Store::FileTree]
      def file_tree
        project.file_tree
      end

      # @return [UriEncoder]
      def uri_encoder
        @uri_encoder ||= UriEncoder.new(root_path)
      end

      # @param path [String]
      # @return [Boolean]
      def program_file?(path)
        %w(.c .rb).include?(File.extname(path))
      end

      class UriEncoder
        # @return [String]
        attr_reader :base_path

        # @param base_path [String]
        def initialize(base_path)
          @base_path = base_path
        end

        # @param path [String]
        # @return [String]
        def uri_of_path(path)
          "file://#{File.expand_path(path, base_path)}"
        end
      end
    end
  end
end
