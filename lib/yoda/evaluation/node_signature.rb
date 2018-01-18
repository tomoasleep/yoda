module Yoda
  module Evaluation
    class NodeSignature
      attr_reader :node, :trace
      # @param node  [::Parser::AST::Node]
      # @param trace [Typing::Traces::Base]
      def initialize(node, trace)
        @node = node
        @trace = trace
      end

      # @return [Range]
      def node_range
        Parsing::Range.of_ast_location(node.location)
      end

      # @return [Array<Descriptions::Base>]
      def descriptions
        case trace
        when Typing::Traces::Send
          trace.functions.map { |function| Descriptions::FunctionDescription.new(function) }.take(1)
        else
          trace.values.map { |value| Descriptions::ValueDescription.new(value) }
        end
      end
    end
  end
end
