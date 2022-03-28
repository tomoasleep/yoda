module Yoda
  module Typing
    class ConstantResolver
      # @abstract
      class Query
        class << self
          # @param node [AST::ConstantNode]
          # @param tracer [Inferencer::Tracer]
          def from_node(node, tracer: nil)
            case node.type
            when :cbase
              CbaseQuery.new
            when :empty
              RelativeBaseQuery.new
            when :const
              MemberQuery.new(parent: from_node(node.base, tracer: tracer), name: node.name.name.to_s, tracer: tracer && NodeTracer.new(node: node, tracer: tracer))
            else
              CodeQuery.new(node: node)
            end
          end

          def from_string(string, parent: RelativeBaseQuery.new)
            base, child = string.split("::", 2)

            case base
            when nil
              parent
            when ""
              base_query = CbaseQuery.new

              if child.nil?
                base_query
              else
                from_string(child, parent: base_query)
              end
            else
              base_query = MemberQuery.new(parent: parent, name: base)

              if child.nil?
                base_query
              else
                from_string(child, parent: base_query)
              end
            end
          end
        end

        # @abstract
        # @return [Query, nil]
        def parent
          fail NotImplementedError
        end

        # @return [NodeTracer, nil]
        def tracer
          nil
        end

        # @return [Query]
        def base
          if parent
            parent.base
          else
            self
          end
        end
      end
    end
  end
end
