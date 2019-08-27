require 'forwardable'

module Yoda
  module Parsing
    class Traverser
      class ResultSet
        extend Forwardable
        include QueryInterface
        include Enumerable

        # @return [Enumerable<AST::Node>]
        attr_reader :nodes
        delegate each: :nodes

        # @params nodes [AST::Node]
        def initialize(nodes)
          @nodes = nodes
        end

        # @return [Enumerable<AST::Node>]
        def all_nodes
          flat_map(&method(:all_nodes_for))
        end

        # @return [Enumerable<AST::Node>]
        def nesting
          flat_map(&method(:nesting))
        end

        # @return [Array<AST::Node>]
        def to_a
          nodes.to_a
        end
      end
    end
  end
end
