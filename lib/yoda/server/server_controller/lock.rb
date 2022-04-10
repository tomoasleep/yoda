module Yoda
  class Server
    class ServerController
      class Lock
        def initialize(initial_lock)
          @locked = initial_lock
          @pending_requests = Concurrent::Array.new
        end

        def lock!
          @locked = true
        end

        # @return [void]
        def request(&block)
          if locked?
            @pending_requests << block
          else
            block.call
          end
        end

        def unlock!
          while request = @pending_requests.shift
            request.call
          end
          @lock_request = false
        end

        # @return [Boolean]
        def locked?
          !!@locked
        end
      end
    end
  end
end
