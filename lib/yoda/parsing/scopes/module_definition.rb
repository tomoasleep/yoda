module Yoda
  module Parsing
    module Scopes
      # Wrapper class for class node.
      # @see https://github.com/whitequark/parser/blob/2.2/doc/AST_FORMAT.md#module
      # ```
      # (module (const nil :Foo) (nil))
      # "module Foo; end"
      #  ~~~~~~ keyword
      #              ~~~ end
      # ```
      class ModuleDefinition < Base
        def const_node
          @const_node ||= NodeObjects::ConstNode.new(node.children[0])
        end

        def body_nodes
          [body_node]
        end

        def body_node
          node.children.last
        end

        def kind
          :module
        end

        # @return [String]
        def scope_name
          const_node.to_s(parent.scope_name)
        end
      end
    end
  end
end
