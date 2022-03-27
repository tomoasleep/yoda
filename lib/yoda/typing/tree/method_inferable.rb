module Yoda
  module Typing
    module Tree
      module MethodInferable
        # @param receiver_type [Types::Type]
        # @return [Types::Type]
        def infer_method_type(receiver_type:)
          value_resolve_context = generator.value_resolve_context(self_type: receiver_type)

          method_candidates = receiver_type.value.select_method(node_name.to_s, visibility: %i(private protected public))
          method_types = method_candidates.map(&:rbs_type).map { |type| value_resolve_context.wrap(type) }

          # TODO: Support overloads
          method_bind = method_types.reduce({}) do |all_bind, method_type|
            bind = Inferencer::ParameterBinder.new(parameters_node.parameter).bind(type: method_type, generator: generator)
            all_bind.merge(bind.to_h) { |_key, v1, v2| generator.union_type(v1, v2) }
          end

          Logger.trace("method_candidates: [#{method_candidates.join(', ')}]")
          Logger.trace("bind arguments: #{method_bind.map { |key, value| [key, value.to_s] }.to_h }")

          bind_method_definition(node: node, method_candidates: method_candidates)

          method_context = context.derive_method_context(receiver_type: receiver_type, binds: method_bind)

          infer_child(body_node, context: method_context)

          generator.symbol_type(node_name.to_sym)
        end

        # @abstract
        # @return [Symbol, string]
        def node_name
          fail NotImplementedError
        end

        # @abstract
        # @return [AST::ParametersNode]
        def parameters_node
          fail NotImplementedError
        end

        # @abstract
        # @return [AST::ParametersNode]
        def body_node
          fail NotImplementedError
        end
      end
    end
  end
end
