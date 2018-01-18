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

      # @return [NodeSignature, nil]
      def current_node_signature
        return nil if !valid? || !current_node_trace
        @current_node_signature ||= NodeSignature.new(current_node, current_node_trace)
      end

      # @return [true, false]
      def valid?
        !!(current_method && current_node)
      end

      private

      # @return [Typing::Trace::Send, nil]
      def current_node_trace
        return nil unless valid?
        @current_node_trace ||= calculate_trace(current_node, registry, current_method)
      end

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
