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

        # @return [Notifier]
        attr_reader :notifier

        # @return [Session]
        attr_reader :session

        # @param notifier [Notifier]
        # @param session [Notifier]
        def initialize(notifier:, session:)
          @notifier = notifier
          @session = session
        end

        # @abstract
        # @param params [Hash]
        def provide(params)
          fail NotImplementedError
        end
      end
    end
  end
end
