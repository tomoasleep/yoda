require 'yoda/typing/tree/send_inferable'

module Yoda
  module Typing
    module Tree
      class BlockCall < Base
        include SendInferable

        # @!method node
        #   @return [AST::BlockCallNode]

        # @return [Types::Type]
        def infer_type
          infer_send(node.send_clause, node.parameters, node.body)
        end
      end
    end
  end
end
