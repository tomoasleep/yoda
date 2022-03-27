module Yoda
  module Typing
    module Tree
      module SendInferable
        # @param send_node [AST::SendNode]
        # @param block_param_node [AST::ParametersNode, nil]
        # @param block_node [AST::Vnode, nil]
        # @return [Types::Type]
        def infer_send(send_node, block_param_node = nil, block_node = nil)
          receiver_type = send_node.implicit_receiver? ? context.receiver : infer_child(send_node.receiver)
          argument_types = infer_argument_nodes(send_node.arguments)
          value_resolve_context = generator.value_resolve_context(self_type: receiver_type)

          visibility = send_node.implicit_receiver? ? %i(private protected public) : %i(public)
          # TODO: Support overloads
          method_candidates = receiver_type.value.select_method(send_node.selector_name, visibility: visibility)
          method_types = method_candidates.map(&:rbs_type).map { |type| value_resolve_context.wrap(type) }

          if block_node
            # TODO: Resolve type variables by matching argument_types with arguments
            binds = Inferencer::ArgumentsBinder.new(generator: generator).bind(types: method_types, arguments: block_param_node.parameter)
            new_context = context.derive_block_context(binds: binds)
            infer_child(block_node, context: new_context)
          end

          Logger.trace("method_candidates: [#{method_candidates.join(', ')}]")
          Logger.trace("receiver_type: #{receiver_type}")

          bind_send(node: node, method_candidates: method_candidates, receiver_type: receiver_type)
          if method_types.empty?
            generator.unknown_type(reason: "method not found")
          else
            generator.union_type(*method_types.map { |method_type| value_resolve_context.wrap(method_type.type.return_type) })
          end
        end

        # @param arguments [Array<AST::Vnode>]
        # @return [{Symbol => Types::Base}]
        def infer_argument_nodes(arguments)
          arguments.each_with_object({}) do |node, obj|
            case node.type
            when :splat
              # TODO
              infer_child(node)
            when :block_pass
              obj[:block_argument] = infer_child(node.children.first)
            else
              obj[:arguments] ||= []
              obj[:arguments].push(infer_child(node))
            end
          end
        end
      end
    end
  end
end
