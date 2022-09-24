
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

      # @return [true, false]
      def namespace?
        true
      end
    end
  end
end
