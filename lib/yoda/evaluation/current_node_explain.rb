module Yoda
  module Evaluation
    class CurrentNodeExplain
      include NodeEvaluatable

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

      # @return [NodeSignature, nil]
      def current_node_signature
        return nil if !valid? || !current_node_trace
        @current_node_signature ||= Models::NodeSignature.new(current_node, current_node_trace)
      end

      # @return [true, false]
      def valid?
        !!(current_method && current_node)
      end

      # @return [Array<[String, Integer]>]
      def defined_files
        return [] if !valid? || !current_node_trace
        case current_node.type
        when :send
          current_node_trace.functions.map { |function| function.defined_files.first }.compact
        when :const
          current_node_trace.values.map { |value| value.defined_files.first }.compact
        else
          []
        end
      end

      private

      # @return [Typing::Traces::Base, nil]
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
