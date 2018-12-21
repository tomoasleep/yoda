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
          method_candidates.map { |function| function.primary_source }.compact
        when :const
          current_node_objects.map { |value| value.primary_source || value.sources.first }.compact
        else
          []
        end
      end

      private

      # @return [Array<Store::Objects::Base>]
      def current_node_objects
        return [] unless valid?
        @current_node_objects ||= evaluator.objects(current_node)
      end

      # @return [Array<Store::Objects::Base>]
      def method_candidates
        return [] unless valid?
        @method_candidates ||= evaluator.method_candidates(current_node)
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
