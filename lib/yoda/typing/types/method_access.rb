module Yoda
  module Typing
    module Types
      class MethodAccess < Base
        # @return [Base]
        attr_reader :receiver_type

        # @return [String]
        attr_reader :method_name

        # @param callee [Base]
        # @param method_name [String]
        # @param with_receiver [true, false]
        def initialize(receiver_type, method_name)
          @receiver_type = receiver_type
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

        def resolve
          method_candidates = receiver_type.value.select_method(method_name, visibility: %i(private protected public))
          method_types = method_candidates.map(&:rbs_type)

          # TODO: Support overloads
          method_bind = method_types.reduce({}) do |all_bind, method_type|
            bind = ParameterBinder.new(node.parameters.parameter).bind(type: method_type, generator: generator)
            all_bind.merge(bind.to_h) { |_key, v1, v2| generator.union_type(v1, v2) }
          end

          Logger.trace("method_candidates: [#{method_candidates.join(', ')}]")
          Logger.trace("bind arguments: #{method_bind.map { |key, value| [key, value.to_s] }.to_h }")

          # tracer.bind_method_definition(node: node, method_candidates: method_candidates)

          method_context = context.derive_method_context(receiver_type: receiver_type, binds: method_bind)
          derive(context: method_context).traverse(node.body)

          generator.symbol_type(method_name)
        end

        def parameter_binder
          fail NotImplementedError
        end

        def visilibity
          %i(private protected public)
        end

        def to_type_string
          "#{callee.to_type_string}##{method_name}"
        end
      end
    end
  end
end
