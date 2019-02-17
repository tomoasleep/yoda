module Yoda
  module Services
    # CurrentNodeExplain shows help for the current node.
    class CurrentNodeExplain
      # @return [Store::Registry]
      attr_reader :registry

      # @return [String]
      attr_reader :source

      # @return [Parsing::Location]
      attr_reader :location

      # @param registry [Store::Registry]
      # @param source   [String]
      # @param location [Parsing::Location]
      def initialize(registry, source, location)
        @registry = registry
        @source = source
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
        analyzer.nodes_to_current_location_from_root.last
      end

      # @return [Evaluator]
      def evaluator
        @evaluator ||= Evaluator.new(ast: analyzer.ast, registry: registry)
      end

      # @return [SourceAnalyzer]
      def analyzer
        @analyzer ||= Parsing::SourceAnalyzer.from_source(source, location)
      end
    end
  end
end
