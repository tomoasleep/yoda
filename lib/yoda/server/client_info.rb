require 'uri'

module Yoda
  class Server
    class ClientInfo
      attr_reader :root_uri, :file_store, :registry, :project

      def initialize(root_uri)
        @root_uri = root_uri
        @file_store = FileStore.new
        @registry = Store::Registry.instance
        @project = Store::Project.new(root_path)
      end

      def root_path
        @root_path ||= file_store.path_of_uri(root_uri)
      end

      def setup
        project.setup
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
        def store(uri_string, text)
          @cache[uri_string] = text
        end

        # @param uri_string [String]
        def load(uri_string)
          store(uri_string, read(uri_string))
        end

        # @param uri_string [String]
        def read(uri_string)
          path = path_of_uri(uri_string)
          fail ArgumentError unless path
          File.read(path)
        end

        # @param uri_string [String]
        def path_of_uri(uri_string)
          uri = URI.parse(uri_string)
          return nil unless uri.scheme == 'file'
          uri.path
        rescue URI::InvalidURIError
          nil
        end
      end
    end
  end
end
