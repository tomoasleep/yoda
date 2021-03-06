module Yoda
  module Typing
    module Types
      # @abstract
      class Base
        def reference?
          false
        end

        # @abstract
        # @param resolver [Resolver]
        # @return [Store::TypeExpressions::Base]
        def to_expression(resolver)
          fail NotImplemetedError
        end

        # @abstract
        # @return [String]
        def to_type_string
          fail NotImplemetedError
        end
      end
    end
  end
end
