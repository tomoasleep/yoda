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

      attr_accessor :client_initialized

      # @param root_uri [String] an uri expression of project root path
      def initialize(root_uri)
        @root_uri = root_uri
        @file_store = FileStore.new
        @project = Store::Project.new(root_path)
        @client_initialized = false
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

      class FileStore
        def initialize
          @cache = {}
        end

        # @param uri_string [String]
        # @return [String, nil]
        def get(uri_string)
          @cache[uri_string]
        end

        # @param uri_string [String]
        # @param text [String]
        def store(uri_string, text)
          return unless program_file_uri?(uri_string)
          @cache[uri_string] = text
        end

        # @param uri_string [String]
        def load(uri_string)
          store(uri_string, read(uri_string))
        end

        # @param uri_string [String]
        def read(uri_string)
          path = self.class.path_of_uri(uri_string)
          fail ArgumentError unless path
          File.read(path)
        end

        # @param path [String]
        def self.uri_of_path(path)
          "file://#{File.expand_path(path)}"
        end

        # @param uri_string [String]
        def self.path_of_uri(uri_string)
          uri = URI.parse(uri_string)
          return nil unless uri.scheme == 'file'
          uri.path
        rescue URI::InvalidURIError
          nil
        end

        # @param uri_string [String]
        def program_file_uri?(uri_string)
          %w(.c .rb).include?(File.extname(URI.parse(uri_string).path))
        rescue URI::InvalidURIError => _e
          false
        end
      end
    end
  end
end
