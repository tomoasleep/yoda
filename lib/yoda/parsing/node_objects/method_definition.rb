module Yoda
  module Parsing
    module NodeObjects
      class MethodDefinition

        # @return [::Parser::AST::Node]
        attr_reader :node

        # @return [Namespace]
        attr_reader :namespace

        # @param node [::Parser::AST::Node]
        # @param namespace [Namespace]
        def initialize(node, namespace)
          fail ArgumentError, node unless node.is_a?(::Parser::AST::Node)
          fail ArgumentError, namespace unless namespace.is_a?(Namespace)
          @node = node
          @namespace = namespace
        end

        # @return [Symbol]
        def name
          node.children[-3]
        end

        def arg_node
          node.children[-2]
        end

        def body_node
          node.children[-1]
        end

        # @return [String]
        def full_name
          "#{namespace.full_name}##{name}"
        end

        # @return [String]
        def namespace_name
          namespace.full_name
        end
      end
    end
  end
end
