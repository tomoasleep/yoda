module Yoda
  module Parsing
    module NodeObjects
      class Namespace
        include AstTraversable

        # @return [::Parser::AST::Node]
        attr_reader :node

        # @return [Namespace, nil]
        attr_reader :parent

        # @param node [::Parser::AST::Node]
        # @param parent [Namespace, nil]
        def initialize(node, parent = nil)
          fail ArgumentError, node unless node.is_a?(::Parser::AST::Node)
          fail ArgumentError, parent unless !parent || parent.is_a?(Namespace)
          @node = node
          @parent = parent
        end

        # @return [::Parser::AST::Node]
        def body_node
          return node if type == :root
          return node.children[2] if type == :class
          node.children[1]
        end

        # @return [::Parser::AST::Node, nil]
        def const_node
          %i(root sclass).include?(type) ? nil : node.children[0]
        end

        # @return [Namespace]
        def child_namespaces
          @child_namespaces ||= child_nodes_of(body_node).select { |node| %i(module class sclass).include?(node.type) }.map { |node| self.class.new(node, self) }
        end

        # @return [Wrappers::MethodNodeWrapper]
        def child_methods
          @child_methods ||= child_nodes_of(body_node).select { |node| %i(def defs).include?(node.type) }.map { |node| MethodDefinition.new(node, self) }
        end

        def type
          @type ||= begin
            return node.type if %i(module class sclass).include?(node.type)
            :root
          end
        end

        # @return [String]
        def path
          name = full_name
          name == :root ? '' : name
        end

        # @return [true, false]
        def root?
          type == :root
        end

        # @return [String, Symbol]
        def full_name
          return :root if type == :root
          parent_name = parent && !parent.root? ? parent.full_name : ''
          const_node ? ConstNode.new(const_node).to_s(parent_name) : parent_name
        end

        # @return [Array<String>]
        def paths_from_root
          if root?
            [path]
          else
            parent ? parent.paths_from_root + [path] : ['', path]
          end
        end

        # @param location [Location]
        # @return [Namespace, nil]
        def calc_current_location_namespace(location)
          return nil unless location.included?(node.location)
          including_child_namespace = child_namespaces.find { |namespace| location.included?(namespace.node.location) }
          including_child_namespace ? including_child_namespace.calc_current_location_namespace(location) : self
        end

        # @param location [Location]
        # @return [MethodNodeWrapper, nil]
        def calc_current_location_method(location)
          namespace = calc_current_location_namespace(location)
          namespace && namespace.child_methods.find { |method| location.included?(method.node.location) }
        end

        private

        def child_nodes_of(node)
          # @todo evaluate nodes in the namespace
          return [] unless node
          return node.children.map { |child| child_nodes_of(child) }.flatten.compact if node.type == :begin
          [node]
        end
      end
    end
  end
end
