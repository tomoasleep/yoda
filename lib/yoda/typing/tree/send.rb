module Yoda
  module Typing
    module Tree
      class Send < Base
        def receiver
          @receiver ||= node.children[0] && build_child(node.children[0])
        end

        # @return [Symbol]
        def method_name
          @method_name ||= node.children[1]
        end

        # @return [Symbol]
        def arguments
          @arguments ||= node.children.slice(2..-1).map(&method(:build_child))
        end

        # @param block_param_node [::AST::Node, nil]
        # @param block_node [::AST::Node, nil]
        # @return [Types::Base]
        def infer_send_node(block_param_node = nil, block_node = nil)
          if block_node
            new_context = method_resolver.generate_block_context(context: context, block_param_node: block_param_node)
            derive(context: new_context).infer(block_node)
          end

          tracer.bind_send(node: node, method_candidates: method_resolver.method_candidates, receiver_candidates: method_resolver.receiver_candidates)
          method_resolver.return_type
        end

        def method_resolver
          @method_resolver ||= MethodResolver.new(
            registry: context.registry,
            receiver_type: receiver_type,
            name: method_name.to_s,
            argument_types: argument_types,
            generator: generator,
            implicit_receiver: receiver.nil?,
          )
        end

        def receiver_type
          @receiver_type ||= receiver ? receiver.type : context.receiver
        end

        def block_context
          @block_context ||= method_resolver.generate_block_context(context: context, block_param_node: block_param_node)
        end

        private

        # @return [{Symbol => Types::Base}]
        def argument_types
          @argument_types ||= argument_nodes.each_with_object({}) do |node, obj|
            case node.type
            when :splat
              # TODO
              node.type
            when :blockarg
              obj[:block_argument] = infer(node.children.first)
            else
              obj[:arguments] ||= []
              obj[:arguments].push(node.type)
            end
          end
        end
      end
    end
  end
end
