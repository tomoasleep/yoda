module Yoda
  module Evaluation
    class CurrentNodeExplain
      include NodeEvaluatable
      attr_reader :registry, :source, :location

      # @param registry [Registry]
      # @param source   [String]
      # @param location [Location]
      def initialize(registry, source, location)
        @registry = registry
        @source = source
        @location = location
      end

      # @return [Range]
      def current_node_range
        Parsing::Range.of_ast_location(current_node.location)
      end

      # @return [Array<Store::Values::Base>]
      def current_node_values
        return [] unless valid?
        @current_node_value ||= calculate_values(current_node, registry, current_method)
      end

      # @return [true, false]
      def valid?
        !!(current_method && current_node)
      end

      private

      # @return [SourceAnalyzer]
      def analyzer
        @analyzer ||= Parsing::SourceAnalyzer.from_source(source, location)
      end

      # @return [Parser::AST::Node]
      def current_node
        analyzer.nodes_to_current_location_from_root.last
      end

      # @return [Parsing::NodeObjects::MethodDefition, nil]
      def current_method
        analyzer.current_method
      end
    end
  end
end
