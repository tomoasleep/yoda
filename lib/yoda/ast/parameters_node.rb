module Yoda
  module AST
    class ParametersNode < Node
      # @return [Array<ParameterNode>]
      def parameter_clauses
        children
      end

      # @return [Model::Parameters::Multiple]
      def parameter
        Model::Parameters::Multiple.new(
          parameters: parameter_nodes.map(&:parameter),
          rest_parameter: rest_parameter_node&.parameter,
          post_parameters: post_parameter_nodes.map(&:parameter),
          keyword_parameters: keyword_parameter_nodes.map(&:parameter),
          keyword_rest_parameter: keyword_rest_parameter_node&.parameter,
          block_parameter: block_parameter_node&.parameter,
        )
      end

      # @return [Array<::AST::Node>]
      def parameter_nodes
        @parameter_nodes ||= children.take_while { |arg_node| %i(arg optarg mlhs).include?(arg_node.type) }
      end

      # @return [::AST::Node, nil]
      def rest_parameter_node
        @rest_parameter_node ||= children.find { |arg_node| arg_node.type == :restarg }
      end

      # @return [Array<::AST::Node>]
      def post_parameter_nodes
        @post_parameter_nodes ||= children.drop_while { |arg_node| %i(arg optarg mlhs).include?(arg_node.type) }.select { |arg_node| %i(arg optarg mlhs).include?(arg_node.type) }
      end

      # @return [Array<::AST::Node>]
      def keyword_parameter_nodes
        @keyword_parameter_nodes ||= children.select { |arg_node| %i(kwarg kwoptarg).include?(arg_node.type) }
      end

      # @return [::AST::Node, nil]
      def keyword_rest_parameter_node
        @keyword_rest_parameter_node ||= children.find { |arg_node| arg_node.type == :kwrestarg }
      end

      # @return [Node]
      def block_parameter_node
        @block_parameter_node ||= children.find { |arg_node| arg_node.type == :blockarg }
      end
    end
  end
end
