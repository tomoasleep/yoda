require 'uri'

module Yoda
  class Server
    class ClientInfo
      # @!attribute [r] root_uri
      #   @return [String]
      # @!attribute [r] file_store
      #   @return [FileStore]
      # @!attribute [r] registry
      #   @return [Store::Registry]
      # @!attribute [r] project
      #   @return [Store::Project]
      attr_reader :root_uri, :file_store, :registry, :project

      # @param root_uri [String] an uri expression of project root path
      def initialize(root_uri)
        @root_uri = root_uri
        @file_store = FileStore.new
        @registry = Store::Registry.instance
        @project = Store::Project.new(root_path)
      end

      def root_path
        @root_path ||= FileStore.path_of_uri(root_uri)
      end

      def setup
        project.setup
      end

      def reparse_doc(uri)
        path = FileStore.path_of_uri(uri)
        project.reparse(path)
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
