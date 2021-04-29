module Yoda
  module Typing
    class Inferencer
      class Arguments
        # @param argument_nodes [Array<AST::Node>]
        # @param tracer [Tracer]
        def initialize(argument_nodes, tracer)
          @argument_nodes = argument_nodes
          @tracer = tracer
        end

        # @param signature [Model::FunctionSignatures::Base]
        # @return [Boolean]
        def accepted_by?(signature)
          signature.parameters
        end

        # @param nodes [Array<::AST::Node>]
        # @return [{Symbol => Types::Base}]
        def infer_argument_nodes(argument_nodes)
          argument_nodes.each_with_object({}) do |node, obj|
            case node.type
            when :splat
              # TODO
              infer(node)
            when :block_pass
              obj[:block_argument] = infer(node.children.first)
            else
              obj[:arguments] ||= []
              obj[:arguments].push(infer(node))
            end
          end
        end

      end
    end
  end
end
