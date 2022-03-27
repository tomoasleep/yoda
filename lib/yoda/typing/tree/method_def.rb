require 'yoda/typing/tree/method_inferable'

module Yoda
  module Typing
    module Tree
      class MethodDef < Base
        include MethodInferable

        # @!method node
        #   @return [AST::DefNode]

        # @return [Types::Base]
        def infer_type
          infer_method_type(receiver_type: self_type)
        end

        # @return [Symbol]
        def node_name
          node.name
        end

        # @return [AST::ParametersNode]
        def parameters_node
          node.parameters
        end

        # @return [Types::Type]
        def body_node
          node.body
        end

        # @return [Types::Type]
        def self_type
          @self_type ||= begin
            context.method_receiver
          end
        end
      end
    end
  end
end
