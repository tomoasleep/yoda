module Yoda
  module Typing
    module Types
      class Untyped < Base
        def to_expression
          Model::TypeExpressions::AnyType.new
        end

        def resolve
          self
        end

        def to_type_string
          "untyped"
        end
      end
    end
  end
end
