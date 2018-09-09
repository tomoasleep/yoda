require 'uri'

module Yoda
  class Server
    class Session
      # @return [String]
      attr_reader :root_uri

      # @return [FileStore]
      attr_reader :file_store

      # @return [Store::Project]
      attr_reader :project

      # @param root_uri [String] an uri expression of project root path
      def initialize(root_uri)
        @root_uri = root_uri
        @file_store = FileStore.new
        @project = Store::Project.new(root_path)
      end

      def root_path
        @root_path ||= FileStore.path_of_uri(root_uri)
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
        project.build_cache
      end

      # @param path [String]
      def uri_of_path(path)
        FileStore.uri_of_path(File.expand_path(path, root_path))
      end

      def reparse_doc(uri)
        path = FileStore.path_of_uri(uri)
        project.read_source(path)
      end
    end
  end
end
