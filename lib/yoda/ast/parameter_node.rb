require 'yoda/ast/parameter_kind_predicates'

module Yoda
  module AST
    class ParameterNode < Node
      include ParameterKindPredicates

      # @return [NameVnode, EmptyNode, nil]
      def content
        children[0]
      end

      # @return [nil]
      def optional_value
        nil
      end

      # @return [Model::Parameters::Base]
      def parameter
        content&.present? ? Model::Parameters::Named.new(content.name) : Model::Parameters::Unnamed.new
      end

      # @return [Model::Parameters::Base]
      def parameter_root
        parameter_root_node.parameter
      end

      # @return [ParametersNode]
      def parameter_root_node
        parent.try(:parameter_root_node)
      end
    end
  end
end
