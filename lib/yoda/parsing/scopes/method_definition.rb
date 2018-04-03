module Yoda
  module Parsing
    module Scopes
      # Wrapper class for instance method node.
      # @see https://github.com/whitequark/parser/blob/2.2/doc/AST_FORMAT.md#instance-methods
      # ```
      # (def :foo (args) nil)
      # "def foo; end"
      #  ~~~ keyword
      #      ~~~ name
      #           ~~~ end
      #  ~~~~~~~~~~~~ expression
      # ```
      class MethodDefinition < Base
        # @return [Symbol]
        def name
          node.children[0]
        end

        # @return [Parser::AST::Node]
        def arg_node
          node.children[1]
        end

        # @return [Parser::AST::Node]
        def body_node
          node.children[2]
        end

        # @return [Array<Parser::AST::Node>]
        def body_nodes
          [body_node]
        end

        # @return [String]
        def full_name
          "#{namespace.full_name}##{name}"
        end

        # @return [String]
        def namespace_name
          namespace.full_name
        end

        def singleton?
          false
        end

        def kind
          :method
        end

        def method?
          true
        end

        # @return [String]
        def scope_name
          parent.scope_name
        end

        # @return [Array<String>]
        def ancestor_scopes
          parent.ancestor_scopes
        end
      end
    end
  end
end
