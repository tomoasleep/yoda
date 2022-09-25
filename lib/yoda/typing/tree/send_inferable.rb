module Yoda
  module Typing
    module Tree
      module SendInferable
        private

        # @!method infer_child(node)
        #   @abstract
        #   @param node [AST::Vnode]
        #   @return [Types::Type]

        # @!method context
        #   @abstract
        #   @return [Contexts::BaseContext]

        # @!method generator 
        #   @abstract
        #   @return [Types::Generator]

        # @param send_node [AST::SendNode]
        # @param block_param_node [AST::ParametersNode, nil]
        # @param block_node [AST::Vnode, nil]
        # @return [Types::Type]
        def infer_send(send_node, block_param_node = nil, block_node = nil)
          receiver_type = send_node.implicit_receiver? ? context.receiver : infer_child(send_node.receiver)
          argument_map = infer_argument_nodes(send_node.arguments)
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
          resolve_require(method_candidates, argument_map)

          if method_types.empty?
            generator.unknown_type(reason: "method not found")
          else
            generator.union_type(*method_types.map { |method_type| value_resolve_context.wrap(method_type.type.return_type) })
          end
        end

        # @param method_candidates [Array<Model::FunctionSignatures::Wrapper>]
        # @param argument_map [{Symbol => Tree}]
        def resolve_require(method_candidates, argument_map)
          return unless method_candidates.any? { |method_candidate| method_candidate.name.to_s == "require" && method_candidate.namespace_path.to_s == "Kernel" }

          first_argument_tree = argument_map[:arguments]&.first
          return unless first_argument_tree

          first_argument_type = first_argument_tree.type
          strings = gather_literals(first_argument_type.value).select { |literal| literal.is_a?(String) }

          require_paths = strings.map { |path| Inferencer::LoadResolver.new(context.environment.registry.project).resolve(path) }.compact
          bind_require_paths(node: first_argument_tree.node, require_paths: require_paths)
        end

        # @param arguments [Array<AST::Vnode>]
        # @return [{Symbol => Tree}]
        def infer_argument_nodes(arguments)
          arguments.each_with_object({}) do |node, obj|
            case node.type
            when :splat
              # TODO
              infer_child(node)
            when :block_pass
              obj[:block_argument] = build_child(node.children.first).tap(&:type)
            else
              obj[:arguments] ||= []
              obj[:arguments].push(build_child(node).tap(&:type))
            end
          end
        end

        # @param value [Model::Values::Base]
        # @return [Array<Object>]
        def gather_literals(value)
          if value.respond_to?(:literal)
            [value.literal]
          elsif value.respond_to?(:values)
            value.values.flat_map { |v| gather_literals(v) }
          elsif value.respond_to?(:value)
            gather_literals(value.value)
          else
            []
          end
        end
      end
    end
  end
end
