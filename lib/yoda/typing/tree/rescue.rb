module Yoda
  module Typing
    module Tree
      class Rescue < Base
        # @!method node
        #   @return [AST::RescueNode]

        # @return [Types::Base]
        def infer_type
          type = infer_child(node.body)
          node.rescue_clauses.each { |rescue_clause| infer_child(rescue_clause) }
          infer_child(node.else_clause)
          type
        end
      end
    end
  end
end
