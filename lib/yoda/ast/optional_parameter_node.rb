module Yoda
  module AST
    class OptionalParameterNode < Node
      # @return [Node]
      def content
        children[0]
      end

      # @return [Node]
      def optional_value
        children[1]
      end

      # @return [Model::Parameters::Base]
      def parameter
        content.present? ? Model::Parameters::Named.new(content.name) : Model::Parameters::Unnamed.new
      end
    end
  end
end
