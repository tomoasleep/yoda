module Yoda
  module Parsing
    class Traverser
      module QueryInterface
        # @return [Traverser, nil]
        def query(**kwargs, &predicate)
          result = select(**kwargs, &predicate).first
          result ? Traverser.new(result) : nil
        end

        # @return [ResultSet]
        def query_all(**kwargs, &predicate)
          select(**kwargs, &predicate)
        end

        private

        # @return [Enumerable<AST::Node>]
        def select(**kwargs, &predicate)
          matcher = Matcher.new(**kwargs, &predicate)
          all_nodes.select { |node| matcher.match?(node) }
        end

        # @param node [AST::Node]
        # @return [Enumerable<AST::Node>]
        def all_nodes_for(node)
          Enumerator.new { |yielder| repeat_for(node, yielder) }.lazy
        end

        # @param node [AST::Node]
        # @param yielder [Enumerator::Yielder]
        def repeat_for(node, yielder)
          yielder << node
          node.children.select { |node| node.is_a?(AST::Node) }.each { |node| repeat_for(node, yielder) }
        end

        # @abstract
        # @return [Enumerable<AST::Node>]
        def all_nodes
          fail NotImplementedError
        end
      end
    end
  end
end
