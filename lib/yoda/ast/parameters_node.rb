module Yoda
  module AST
    class ParametersNode < Node
      # @return [Array<ParameterNode, OptionalParameterNode>]
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
          forward_parameter: forward_parameter_node&.parameter,
        )
      end

      # @return [Array<::AST::Node>]
      def parameter_nodes
        @parameter_nodes ||= children.take_while(&:parameter?)
      end

      # @return [::AST::Node, nil]
      def rest_parameter_node
        @rest_parameter_node ||= children.find(&:rest_parameter?)
      end

      # @return [Array<::AST::Node>]
      def post_parameter_nodes
        @post_parameter_nodes ||= children.drop_while(&:parameter).select(&:parameter?)
      end

      # @return [Array<::AST::Node>]
      def keyword_parameter_nodes
        @keyword_parameter_nodes ||= children.select(&:keyword_parameter?)
      end

      # @return [::AST::Node, nil]
      def keyword_rest_parameter_node
        @keyword_rest_parameter_node ||= children.find(&:keyword_rest_parameter?)
      end

      # @return [Node, nil]
      def block_parameter_node
        @block_parameter_node ||= children.find(&:block_parameter?)
      end

      # @return [Node, nil]
      def forward_parameter_node
        @block_parameter_node ||= children.find(&:forward_parameter?)
      end

      # @return [Model::Parameters::Base]
      def parameter_root
        parameter_root_node.parameter
      end

      # @return [ParametersNode]
      def parameter_root_node
        parent.try(:parameter_root_node) || self
      end
    end
  end
end
