module Yoda
  module Typing
    module Traces
      # Store evaluation result for each ast node.
      # @abstract
      class Base
        # @return [Array<Store::Objects::Base>]
        def values
          type.resolve(context.registry)
        end

        # @abstract
        # @return [Model::Types::Base]
        def type
          fail NotImplementedError
        end

        # @abstract
        # @return [Context]
        def context
          fail NotImplementedError
        end
      end
    end
  end
end
