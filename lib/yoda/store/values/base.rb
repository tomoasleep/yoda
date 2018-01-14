module Yoda
  module Store
    module Values
      # @abstract
      class Base
        # @abstract
        # @return [Array<Function>]
        def methods
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def path
          fail NotImplementedError
        end
      end
    end
  end
end
