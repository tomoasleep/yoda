
module Yoda
  module AST
    module Namespace
      # @return [true]
      def root?
        true
      end

      # @return [Namespace, nil]
      def parent_namespace
        parent&.namespace
      end

      # @return [Array<Namespace>]
      def namespace_nestings
        @namespace_nestings ||= (parent_namespace&.namespace_nestings || []) + [self]
      end

      # @return [Namespace]
      def namespace
        self
      end

      # @return [String]
      def path
        fail NotImplementedError
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
