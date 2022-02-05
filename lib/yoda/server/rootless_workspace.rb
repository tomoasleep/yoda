require 'uri'

module Yoda
  class Server
    class RootlessWorkspace
      # @return [String]
      attr_reader :name

      # @param name [String]
      def initialize(name:)
        @name = name
      end

      def setup
        project.setup
      end

      # @return [Store::Project, nil]
      def project
        @project ||= Store::Project.for_path(nil, name: name)
      end

      # @param path [String]
      def uri_of_path(path)
        FileStore.uri_of_path(File.expand_path(path))
      end

      # @param uri [String]
      # @return [String, nil]
      def read_at(uri)
        path = UriDecoder.path_of_uri(uri)
        path && file_tree.read_at(path)
      end

      # @param path []
      def read_source(uri)
        path = UriDecoder.path_of_uri(uri)
        file_tree.clear_editing_at(path)
      end

      # @param uri [String]
      # @param source [String]
      def store_source(uri:, source:)
        path = UriDecoder.path_of_uri(uri)
        file_tree.set_editing_at(path, source)
      end

      def suburi?(uri)
        true
      end

      def subpath?(path)
        true
      end

      # @return [Store::FileTree]
      def file_tree
        project.file_tree
      end
    end
  end
end
