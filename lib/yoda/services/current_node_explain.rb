module Yoda
  module Services
    # CurrentNodeExplain shows help for the current node.
    class CurrentNodeExplain
      # @return [Evaluator]
      attr_reader :evaluator

      # @return [Parsing::Location]
      attr_reader :location

      # @param registry [Store::Registry]
      # @param source   [String]
      # @param location [Parsing::Location]
      # @return [CurrentNodeExplain]
      def self.from_source(registry:, source:, location:)
        new(
          evaluator: Evaluator.new(registry: registry, ast: Parsing::Parser.new.parse(source)),
          location: location
        )
      end

      # @param evaluator [Evaluator]
      # @param location [Parsing::Location]
      def initialize(evaluator:, location:)
        @evaluator = evaluator
        @location = location
      end

      # @return [Model::NodeSignature, nil]
      def current_node_signature
        return nil if !valid? || !current_node
        @current_node_signature ||= Model::NodeSignatures.for_node_info(current_node_info)
      end

      # @return [true, false]
      def valid?
        !!(current_node)
      end

      private

      # @return [Typing::NodeInfo]
      def current_node_info
        @current_node_info ||= evaluator.node_info(current_node)
      end

      # @return [Parser::AST::Node]
      def current_node
        @current_node ||= evaluator.ast.positionally_nearest_child(location)
      end
    end
  end
end
