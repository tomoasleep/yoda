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
    require 'yoda/server/scheduler'
    require 'yoda/server/workspace'
    require 'yoda/server/rootless_workspace'

    # @return [::LanguageServer::Protocol::Transport::Stdio::Reader]
    attr_reader :reader

    # @return [ConcurrentWriter]
    attr_reader :writer

    # @return [RootHandler]
    attr_reader :root_handler

    # Use this value as return value for notification handling
    NO_RESPONSE = :no_response

    def initialize(
      reader: LanguageServer::Protocol::Transport::Stdio::Reader.new,
      writer: LanguageServer::Protocol::Transport::Stdio::Writer.new,
      root_handler_class: RootHandler
    )
      @reader = reader
      @writer = ConcurrentWriter.new(writer)
      @root_handler = RootHandler.new(writer: @writer)
    end

    def run
      Logger.trace "Server initializing..."
      reader.read do |request|
        begin
          root_handler.handle(id: request[:id], method: request[:method].to_sym, params: deserialize(request[:params]))
        rescue StandardError => ex
          Logger.warn ex
          Logger.warn ex.full_message
        end
      end
      Logger.trace "Waiting to finish all pending tasks..."
      root_handler.wait_for_termination(timeout: 10)
      Logger.trace "Server finishing..."
    end

    def deserialize(hash)
      Deserializer.new.deserialize(hash || {})
    end
  end
end
