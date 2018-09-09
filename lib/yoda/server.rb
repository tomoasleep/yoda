require 'language_server-protocol'
require 'securerandom'

module Yoda
  class Server
    require 'yoda/server/session'
    require 'yoda/server/file_store'
    require 'yoda/server/concurrent_writer'
    require 'yoda/server/notifier'
    require 'yoda/server/providers'
    require 'yoda/server/root_handler'
    require 'yoda/server/lifecycle_handler'
    require 'yoda/server/deserializer'

    # @return [::LanguageServer::Protocol::Transport::Stdio::Reader]
    attr_reader :reader

    # @return [ConcurrentWriter]
    attr_reader :writer

    # Use this value as return value for notification handling
    NO_RESPONSE = :no_response

    def initialize
      @reader = LanguageServer::Protocol::Transport::Stdio::Reader.new
      @writer = ConcurrentWriter.new(LanguageServer::Protocol::Transport::Stdio::Writer.new)
    end

    # @return [Notifier]
    def root_handler
      @root_handler ||= RootHandler.new(writer: writer)
    end

    def run
      reader.read do |request|
        begin
          root_handler.handle(id: request[:id], method: request[:method].to_sym, params: deserialize(request[:params]))
        rescue StandardError => ex
          Logger.warn ex
          Logger.warn ex.backtrace
        end
      end
    end

    def deserialize(hash)
      Deserializer.new.deserialize(hash || {})
    end
  end
end
