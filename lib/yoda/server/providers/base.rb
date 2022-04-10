module Yoda
  class Server
    module Providers
      # @abstract
      class Base
        class << self
          # @abstract
          # @return [Symbol]
          def provider_method
            fail NotImplementedError
          end

          # @param method [Symbol]
          def provide?(method)
            provider_method == method
          end
        end

        # @return [Session]
        attr_reader :session

        # @return [ServerController]
        attr_reader :server_controller

        # @param server_controller [ServerController]
        # @param session [Notifier]
        def initialize(server_controller:, session:)
          @server_controller = server_controller
          @session = session
        end

        # @abstract
        # @param params [Hash]
        def provide(params)
          fail NotImplementedError
        end

        # @return [Notifier]
        def notifier
          server_controller.notifier
        end

        # @return [Integer, nil] Seconds to timeout the task. if nil, the task does not timeout.
        def timeout
          nil
        end
      end
    end
  end
end
