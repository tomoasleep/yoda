module Yoda
  class Server
    # Wrapper class for writer to make thread safe
    class ConcurrentWriter
      # @param [::LanguageServer::Protocol::Transport::Stdio::Writer]
      def initialize(channel)
        @channel = channel
        @mutex = Mutex.new
      end

      def write(*args)
        @mutex.synchronize { @channel.write(*args) }
      end
    end
  end
end
