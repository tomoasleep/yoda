module Yoda
  module Parsing
    module NodeObjects
      class MlhsNode
        # @param node [::AST::Node]
        attr_reader :node

        # @param node [::AST::Node]
        def initialize(node)
          fail ArgumentError, node unless node.is_a?(::AST::Node) && node.type == :mlhs
          @node = node
        end

        # @return [Array<::AST::Node>]
        def pre_nodes
          @pre_nodes ||= node.children.take_while { |arg_node| %i(arg optarg mlhs).include?(arg_node.type) }
        end

        # @return [::AST::Node, nil]
        def rest_node
          @rest_node ||= node.children.find { |arg_node| arg_node.type == :restarg }
        end

        # @return [Array<::AST::Node>]
        def post_nodes
          @post_nodes ||= node.children.drop_while { |arg_node| %i(arg optarg mlhs).include?(arg_node.type) }.select { |arg_node| %i(arg optarg mlhs).include?(arg_node.type) }
        end
      end
    end
  end
end
