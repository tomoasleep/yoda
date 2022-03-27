require 'yoda/typing/tree/method_inferable'

module Yoda
  module Typing
    module Tree
      class SingletonMethodDef < Base
        include MethodInferable

        # @!method node
        #   @return [AST::DefSingletonNode]

        # @return [Types::Base]
        def infer_type
          infer_method_type(receiver_type: receiver_type)
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
        def receiver_type
          @receiver_type ||= begin
            infer_child(node.receiver)
          end
        end
      end
    end
  end
end
