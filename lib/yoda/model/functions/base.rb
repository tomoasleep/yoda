module Yoda
  module Store
    module Functions
      # @abstract
      class Base
        # @return [Types::FunctionType]
        def type
          types.first || Types::FunctionType.new(return_type: Types::AnyType.new)
        end

        # @abstract
        # @return [Array<Types::FunctionType>]
        def types
          fail NotImplementedError
        end

        # @abstract
        # @return [Symbol]
        def visibility
          fail NotImplementedError
        end

        # @abstract
        # @return [Array<Overload>]
        def overloads
          fail NotImplementedError
        end

        # @abstract
        # @return [Symbol]
        def scope
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def name
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def docstring
          fail NotImplementedError
        end

        # @abstract
        # @return [Array<[String, Integer]>]
        def defined_files
          fail NotImplementedError
        end

        # @abstract
        # @return [String]
        def name_signature
          fail NotImplementedError
        end

        # @return [String]
        def type_signature
          type.method_type_signature
        end
      end
    end
  end
end
