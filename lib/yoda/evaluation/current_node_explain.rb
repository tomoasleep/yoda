module Yoda
  module Evaluation
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
        return nil if !valid? || !current_node_trace
        @current_node_signature ||= Model::NodeSignature.new(current_node, current_node_trace)
      end

      # @return [true, false]
      def valid?
        !!(current_node)
      end

      # @return [Array<(String, Integer, Integer)>]
      def defined_files
        return [] if !valid? || !current_node_trace
        case current_node.type
        when :send
          current_node_trace.functions.map { |function| function.primary_source }.compact
        when :const
          current_node_trace.values.map { |value| value.primary_source || value.sources.first }.compact
        else
          []
        end
      end

      private

      # @return [Typing::Traces::Base, nil]
      def current_node_trace
        return nil unless valid?
        @current_node_trace ||= evaluator.calculate_trace(current_node)
      end

      # @return [Parser::AST::Node]
      def current_node
        analyzer.nodes_to_current_location_from_root.last
      end

      # @return [Evaluator]
      def evaluator
        @evaluator ||= Evaluator.from_ast(registry, analyzer.ast, location)
      end

      # @return [SourceAnalyzer]
      def analyzer
        @analyzer ||= Parsing::SourceAnalyzer.from_source(source, location)
      end
    end
  end
end
