module Yoda
  module Parsing
    module NodeObjects
      class MethodDefinition
        attr_reader :node, :namespace
        # @param node [::Parser::AST::Node]
        # @param namespace [Namespace]
        def initialize(node, namespace)
          fail ArgumentError, node unless node.is_a?(::Parser::AST::Node)
          fail ArgumentError, namespace unless namespace.is_a?(Namespace)
          @node = node
          @namespace = namespace
        end

        def name
          node.children[-3]
        end

        def arg_node
          node.children[-2]
        end

        def body_node
          node.children[-1]
        end

        def full_name
          "#{namespace.full_name}##{name}"
        end

        # @param registry [Parsing::NodeObjects::MethodDefinition]
        # @return [Base]
        def caller_value(registry)
          code_object = registry.find_or_proxy(namespace.full_name)
          Store::Values::InstanceValue.new(registry, code_object)
        end
      end
    end
  end
end
