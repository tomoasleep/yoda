module Yoda
  module Typing
    module Types
      class Method < Base
        # @return [Base]
        attr_reader :callee

        # @return [String]
        attr_reader :method_name

        # @param callee [Base]
        # @param method_name [String]
        # @param with_receiver [true, false]
        def initailize(callee, method_name, with_receiver: false)
          @callee = callee
          @method_name = method_name
        end

        def to_expression(resolver)
          callee_type = to_expression(callee)
          values = callee_type.instanciate(resolver.registry)
          Model::TypeExpressions::UnionType.new(
            values.map do |value|
              value.methods(visibility: visibility).select { |func| func.name == method_name }
            end.flatten
          )
        end

        def visilibity
          @self_call ? [:private, :public, :protected] : [:public]
        end

        def to_type_string
          "#{callee.to_type_string}##{method_name}"
        end
      end
    end
  end
end
