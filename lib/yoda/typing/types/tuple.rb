module Yoda
  module Typing
    module Types
      class Tuple < Base
        # @return [Array<Base>]
        attr_reader :types

        # @param types [Array<Base>]
        def initailize(*types)
          @types = types
        end

        def to_expression
          Model::TypeExpressions::InstanceType.new('Array')
        end

        def to_type_string
          inner = types.map(&:to_type_string)
          "(#{inner.join(', ')})"
        end
      end
    end
  end
end
