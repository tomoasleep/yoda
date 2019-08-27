module Yoda
  module AST
    module Traversable
      # @return [Vnode, nil]
      def query(query)
        Parsing::Traverser.new(self).query(query)&.node
      end

      # @return [Parsing::Traverser::ResultSet]
      def query_all(query)
        Parsing::Traverser.new(self).query(query)
      end

      # @return [Vnode, nil]
      def query_ancestor(query)
        Parsing::Traverser.new(self).query_ancestor(query)&.node
      end

      # @return [Parsing::Traverser::ResultSet]
      def query_ancestors(query)
        Parsing::Traverser.new(self).query_ancestors(query)
      end
    end
  end
end
