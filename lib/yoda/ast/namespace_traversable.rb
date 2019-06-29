
module Yoda
  module AST
    module Namespace
      # @return [true, false]
      def root?
        false
      end

      # @return [Namespace]
      def namespace
        @namespace ||= namespace? ? self : parent.namespace
      end

      # @return [String]
      def namespace_path
        namespace.path
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
