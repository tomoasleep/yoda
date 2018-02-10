module Yoda
  module Typing
    module Traces
      # Store evaluation result for each ast node.
      # @abstract
      class Base
        # @return [Array<Store::Values::Base>]
        def values
          fail NotImplementedError
        end

        # @return [Model::Types::Base]
        def type
          fail NotImplementedError
        end
      end
    end
  end
end
