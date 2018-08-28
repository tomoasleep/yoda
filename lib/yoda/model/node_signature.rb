module Yoda
  module Model
    class NodeSignature
      # @return [::Parser::AST::Node]
      attr_reader :node

      # @return [Typing::Traces::Base]
      attr_reader :trace

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
        [top_description, *type_descriptions]
      end

      # @return [Descriptions::NodeDescription]
      def top_description
        Descriptions::NodeDescription.new(node, trace)
      end

      # @return [Array<Descriptions::Base>]
      def type_descriptions
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
