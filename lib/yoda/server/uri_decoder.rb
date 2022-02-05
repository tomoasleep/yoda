
module Yoda
  class Server
    module UriDecoder
      # @param uri_string [String]
      # @return [String, nil]
      def self.path_of_uri(uri_string)
        uri = URI.parse(uri_string)
        return nil unless uri.scheme == 'file'
        uri.path
      rescue URI::InvalidURIError
        nil
      end
    end
  end
end
