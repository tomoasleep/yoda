require 'yoda/typing/tree/literal_inferable'

module Yoda
  module Typing
    module Tree
      class Literal < Base
        include LiteralInferable

        # @!method node
        #  @return [AST::LiteralNode, AST::Node]

        def infer_type
          infer_literal(node)
        end
      end
    end
  end
end
