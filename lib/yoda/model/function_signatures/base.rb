module Yoda
  module Store
    module FunctionSignatures
      # @abstract
      class Base
        # @abstract
        # @return [Types::FunctionType]
        def type
          fail NotImplementedError
        end

        # @abstract
        # @return [Symbol]
        def visibility
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def name
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def document
          fail NotImplementedError
        end

        # @abstract
        # @return [ParameterList]
        def parameters
          fail NotImplementedError
        end

        # @abstract
        # @return [Array<[String, Integer]>]
        def sources
          fail NotImplementedError
        end
      end
    end
  end
end
