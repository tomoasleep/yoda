module Yoda
  module Typing
    module Tree
      class RescueClause < Base
        # @!method node
        #   @return [AST::RescueClauseNode]

        # @return [Types::Type]
        def infer_type
          binds = {}

          exception_type = begin
            if node.match_clause
              case node.match_clause.type
              when :array
                generator.union_type(*node.match_clause.contents.map { |content| infer_child(content).instance_type })
              when :empty
                generator.standard_error_type
              else
                # Unexpected
                generator.standard_error_type
              end
            else
              generator.standard_error_type
            end
          end


          if node.assignee
            case node.assignee.type
            when :lvasgn
              binds[node.assignee.assignee.name] = exception_type
            end
          end

          new_context = context.derive_block_context(binds: binds)
          infer_child(node.body, context: new_context)
        end
      end
    end
  end
end
