module Yoda
  module Typing
    module Types
      class Any < Base
        def to_expression(resolver)
          Store::TypeExpressions::AnyType.new
        end
      end
    end
  end
end
