module Yoda
  module Typing
    class Relation
      attr_reader :left, :right, :op
      # @param left  [Symbol, Model::Types::Base]
      # @param right [Symbol, Model::Types::Base]
      # @param op    [Symbol]
      def initialize(left, right, op = :eq)
        @left = left
        @right = right
        @op = op
      end
    end
  end
end
