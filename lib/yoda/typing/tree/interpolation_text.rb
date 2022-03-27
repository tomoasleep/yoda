require 'yoda/typing/tree/literal_inferable'

module Yoda
  module Typing
    module Tree
      class InterpolationText < Base
        include LiteralInferable

        # @!method node
        #   @return [AST::InterpolationTextNode]

        # @return [Types::Type]
        def infer_type
          node.children.each { |node| infer_child(node) }

          infer_literal(node)
        end
      end
    end
  end
end
