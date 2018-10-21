module Yoda
  module Typing
    class Relation
      attr_reader :left, :right, :op
      # @param left  [Symbol, Model::TypeExpressions::Base]
      # @param right [Symbol, Model::TypeExpressions::Base]
      # @param op    [Symbol]
      def initialize(left, right, op = :eq)
        @left = left
        @right = right
        @op = op
      end
    end
  end
end
