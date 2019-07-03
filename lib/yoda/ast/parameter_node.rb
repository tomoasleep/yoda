module Yoda
  module AST
    class ParameterNode < Node
      # @return [NameVnode, EmptyNode]
      def content
        children[0]
      end

      # @return [Model::Parameters::Base]
      def parameter
        content.present? ? Model::Parameters::Named.new(content.name) : Model::Parameters::Unnamed.new
      end
    end
  end
end
