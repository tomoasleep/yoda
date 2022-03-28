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
          if node.send_clause.type == :send
            infer_send(node.send_clause, node.parameters, node.body)
          else
            # super or zsuper
            child_type = infer_child(node.send_clause)
            infer_child(node.body)
            child_type
          end
        end
      end
    end
  end
end
