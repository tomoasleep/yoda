require 'uri'

module Yoda
  class Server
    class RootlessWorkspace
      # @return [FileStore]
      attr_reader :file_store

      # @return [String]
      attr_reader :name

      # @param name [String]
      def initialize(name:)
        @name = name
        @file_store = FileStore.new
      end

      def setup
        project.setup
      end

      # @return [Store::Project, nil]
      def project
        @project ||= Store::Project.new(name: name, root_path: nil)
      end

      # @param path [String]
      def uri_of_path(path)
        FileStore.uri_of_path(File.expand_path(path))
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
        true
      end

      def subpath?(path)
        true
      end
    end
  end
end
