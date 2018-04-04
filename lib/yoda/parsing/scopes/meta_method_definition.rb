module Yoda
  module Parsing
    module Scopes
      # Wrapper class for singleton method node.
      # @see https://github.com/whitequark/parser/blob/2.2/doc/AST_FORMAT.md#singleton-methods
      # ```
      # (defs (self) :foo (args) nil)
      # "def self.foo; end"
      #  ~~~ keyword
      #           ~~~ name
      #                ~~~ end
      #  ~~~~~~~~~~~~~~~~~ expression
      # ```
      class SingletonMethodDefinition < Base
        # @return [Symbol]
        def name
          node.children[1]
        end

        # @return [Parser::AST::Node]
        def arg_node
          node.children[2]
        end

        # @return [Parser::AST::Node]
        def body_node
          node.children[3]
        end

        # @return [Array<Parser::AST::Node>]
        def body_nodes
          [body_node]
        end

        def body_node
          node.children[3]
        end

        # @return [String]
        def full_name
          "#{namespace.full_name}##{name}"
        end

        # @return [String]
        def namespace_name
          namespace.full_name
        end

        def kind
          :meta_method
        end

        def method?
          true
        end

        # @return [String]
        def scope_name
          parent.scope_name
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
