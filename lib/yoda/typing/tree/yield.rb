require 'yoda/typing/tree/literal_inferable'

module Yoda
  module Typing
    module Tree
      class Yield < Base
        include LiteralInferable

        # @!method node
        #   @return [AST::SpecialCallNode]

        def infer_type
          # TODO
          infer_literal(node)
        end
      end
    end
  end
end
