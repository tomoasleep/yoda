module Yoda
  module Parsing
    module Scopes
      # Wrapper class for singleton class node.
      # @see https://github.com/whitequark/parser/blob/2.2/doc/AST_FORMAT.md#singleton-class
      # ```
      # (sclass (lvar :a) (nil))
      # "class << a; end"
      #  ~~~~~ keyword
      #        ~~ operator
      #              ~~~ end
      #  ~~~~~~~~~~~~~~~ expression
      # ```
      class SingletonClassDefinition < Base
        def instance_node
          node.children[0]
        end

        def body_nodes
          [body_node]
        end

        def body_node
          node.children.last
        end

        def kind
          :meta_class
        end

        # @return [String]
        def scope_name
          const_node.to_s(parent.scope_name)
        end

        # @param current_location [Location]
        # @return [Namespace, nil]
        def find_evaluation_root_scope(current_location)
          return nil
        end
      end
    end
  end
end
