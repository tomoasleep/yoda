module Yoda
  module AST
    class MultipleLeftHandSideNode < Node
      # @return [Array<Vnode>]
      def pre_nodes
        @pre_nodes ||= children.take_while { |arg_node| %i(arg optarg mlhs).include?(arg_node.type) }
      end

      # @return [Vnode, nil]
      def rest_node
        @rest_node ||= node.children.find { |arg_node| arg_node.type == :restarg }
      end

      # @return [Array<Vnode>]
      def post_nodes
        @post_nodes ||= children.drop_while { |arg_node| %i(arg optarg mlhs).include?(arg_node.type) }.select { |arg_node| %i(arg optarg mlhs).include?(arg_node.type) }
      end

      # @return [Model::Parameters::Base]
      def parameter
        rest_parameter = rest_node&.respond_to?(:parameter) && rest_node.parameter

        Model::Parameters::Multiple.new(
          parameters: pre_nodes.map(&:parameter),
          rest_parameter: rest_parameter,
          post_parameters: post_nodes.map(&:paramter),
        )
      end
    end
  end
end
