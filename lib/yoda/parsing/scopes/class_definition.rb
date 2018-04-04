module Yoda
  module Parsing
    module Scopes
      # Wrapper class for class node.
      # @see https://github.com/whitequark/parser/blob/2.2/doc/AST_FORMAT.md#class
      # ```
      # (class (const nil :Foo) (const nil :Bar) (nil))
      # "class Foo < Bar; end"
      #  ~~~~~ keyword    ~~~ end
      #            ~ operator
      #  ~~~~~~~~~~~~~~~~~~~~ expression
      #
      # (class (const nil :Foo) nil (nil))
      # "class Foo; end"
      #  ~~~~~ keyword
      #             ~~~ end
      #  ~~~~~~~~~~~~~~ expression
      # ```
      class ClassDefinition < Base
        def const_node
          @const_node ||= NodeObjects::ConstNode.new(node.children[0])
        end

        def superclass_const_node
          @superclass_const_node ||= node.children && NodeObjects::ConstNode.new(node.children[1])
        end

        def body_nodes
          [body_node]
        end

        def body_node
          node.children.last
        end

        def kind
          :class
        end

        # @return [String]
        def scope_name
          const_node.to_s(parent.scope_name)
        end
      end
    end
  end
end
