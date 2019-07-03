
module Yoda
  module AST
    module NamespaceTraversable
      # @return [true, false]
      def root?
        false
      end

      # @return [true, false]
      def namespace?
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

      # @param location [Location]
      # @return [Namespace, nil]
      def calc_current_location_namespace(location)
        positionally_nearest_child(location)&.namespace
      end
    end
  end
end
