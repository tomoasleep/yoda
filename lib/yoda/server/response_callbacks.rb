module Yoda
  class Server
    class ResponseCallbacks
      def initialize
        @callbacks = Concurrent::Map.new
      end

      def register_callback(id, &callback)
        @callbacks.merge_pair(id.to_s, [callback]) { |existing_callbacks| existing_callbacks + [callback] }
      end

      def take_callbacks(id)
        @callbacks.delete(id.to_s) || []
      end
    end
  end
end
