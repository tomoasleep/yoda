module Yoda
  module Parsing
    module Scopes
      # Base class for wrapper classes of nodes which create lexical scopes.
      # @abstract
      class Base
        # @return [::Parser::AST::Node]
        attr_reader :node

        # @return [Namespace, nil]
        attr_reader :parent

        # @return [Array<Base>]
        attr_reader :child_scopes

        # @return [Array<MethodDefinition>]
        attr_reader :method_definitions

        # @param node [::Parser::AST::Node]
        # @param parent [Base, nil]
        def initialize(node, parent = nil)
          fail ArgumentError, node unless node.is_a?(::Parser::AST::Node)
          fail ArgumentError, parent if parent && !parent.is_a?(Base)
          @node = node
          @parent = parent
          @method_definitions = []
          @child_scopes = []
        end

        # @abstract
        # @return [Array<::Parser::AST::Node>]
        def body_nodes
          fail NotImplementedError
        end

        # @abstract
        # @return [::Parser::AST::Node]
        def body_node
          fail NotImplementedError
        end

        # @param location [Location]
        # @return [true, false]
        def inner_location?(location)
          location.included?(node.location)
        end

        # @abstract
        # @return [Symbol]
        def kind
          fail NotImplementedError
        end

        # @return [true, false]
        def method?
          false
        end

        # @param current_location [Location]
        # @return [Namespace, nil]
        def find_evaluation_root_scope(current_location)
          return nil unless inner_location?(current_location)
          [*child_scopes, *method_definitions].each do |s|
            if scope = s.find_evaluation_root_scope(current_location)
              return scope
            end
          end
          return self
        end

        # @return [Array<String>]
        def ancestor_scopes
          [scope_name, *(parent ? parent.ancestor_scopes : [])]
        end
      end
    end
  end
end
