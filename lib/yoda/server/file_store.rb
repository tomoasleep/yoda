require 'concurrent'

module Yoda
  class Server
    class FileStore
      def initialize
        @cache = Concurrent::Map.new
      end

      # @param uri_string [String]
      # @return [String, nil]
      def get(uri_string)
        @cache[uri_string]
      end

      # @param uri_string [String]
      # @return [String, nil]
      def fetch(uri_string)
        @cache.fetch(uri_string) { fail KeyError.new("File is not stored for #{uri_string}", key: uri_string, receiver: self) }
      end

      # @param uri_string [String]
      # @param text [String]
      def store(uri_string, text)
        return unless program_file_uri?(uri_string)
        @cache[uri_string] = text
      end

      # @param uri_string [String]
      def remove(uri_string)
        return unless program_file_uri?(uri_string)
        @cache.delete(uri_string)
      end

      # @param uri_string [String]
      def load(uri_string)
        if source = read(uri_string)
          store(uri_string, source)
        end
      end

      # @param uri_string [String]
      # @return [String, nil]
      def read(uri_string)
        path = self.class.path_of_uri(uri_string)
        fail ArgumentError unless path
        if File.file?(path)
          File.read(path)
        end
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
