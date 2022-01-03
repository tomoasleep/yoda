module Yoda
  module AST
    # Add query methods to search expected nodes from AST.
    # @see {Yoda::Parsing::Traverser::Matcher} for parameters of query methods.
    # @example
    #   ast.query(type: :if) # => returns a if node
    #   ast.query(name: :hoge) # => returns a node about an object with the name
    module Traversable
      # @param query [Hash] (See {Yoda::Parsing::Traverser::Matcher.new} for detailed parameters)
      # @return [Vnode, nil]
      def query(**query)
        Parsing::Traverser.new(self).query(**query)&.node
      end

      # @param query [Hash] (See {Yoda::Parsing::Traverser::Matcher.new} for detailed parameters)
      # @return [Parsing::Traverser::ResultSet]
      def query_all(**query)
        Parsing::Traverser.new(self).query(**query)
      end

      # @param query [Hash] (See {Yoda::Parsing::Traverser::Matcher.new} for detailed parameters)
      # @return [Vnode, nil]
      def query_ancestor(**query)
        Parsing::Traverser.new(self).query_ancestor(**query)&.node
      end

      # @param query [Hash] (See {Yoda::Parsing::Traverser::Matcher.new} for detailed parameters)
      # @return [Parsing::Traverser::ResultSet]
      def query_ancestors(**query)
        Parsing::Traverser.new(self).query_ancestors(**query)
      end
    end
  end
end
