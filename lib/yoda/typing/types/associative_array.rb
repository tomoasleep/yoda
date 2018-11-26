module Yoda
  module Typing
    module Types
      class AssociativeArray < Base
        # @return [::Hash{ String, Symbol => Base }]
        attr_reader :contents

        # @param hash [::Hash{ String, Symbol => Base }]
        def initailize(contents:)
          @contents = contents
        end

        def to_expression(resolver)
          callee_type = to_expression(callee)
          values = callee_type.instanciate(resolver.registry)
          Store::TypeExpressions::UnionType.new(
            values.map do |value|
              value.methods(visibility: visibility).select { |func| func.name == method_name }
            end.flatten
          )
        end

        def visilibity
          @self_call ? [:private, :public, :protected] : [:public]
        end
      end
    end
  end
end
