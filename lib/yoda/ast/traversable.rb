module Yoda
  module AST
    module Traversable
      # @return [Vnode, nil]
      def query(query)
        Traverser.new(self).query&.node
      end

      # @return [Parsing::Traverser::ResultSet]
      def query_all(query)
        Traverser.new(self).query
      end

      # @return [Vnode, nil]
      def query_ancestor(query)
        Traverser.new(self).query_ancestor&.node
      end

      # @return [Parsing::Traverser::ResultSet]
      def query_ancestors(query)
        Traverser.new(self).query_ancestors
      end
    end
  end
end
