module Yoda
  module Evaluation
    class FindDefinition
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

      # @return [Array<[String, Integer]>]
      def current_const_references
        return [] unless valid?
        [const_object].compact.map { |el| el.files.first }.compact
      end

      # @return [true, false]
      def valid?
        !!(current_const_node && current_namespace)
      end

      private

      # @return [SourceAnalyzer]
      def analyzer
        @analyzer ||= Parsing::SourceAnalyzer.from_source(source, location)
      end

      # @return [Parsing::NodeObjects::ConstNode, nil]
      def current_const_node
        @current_const_node ||= begin
          current_node.type == :const ? Parsing::NodeObjects::ConstNode.new(current_node) : nil
        end
      end

      # @return [Parser::AST::Node, nil]
      def current_node
        analyzer.nodes_to_current_location_from_root.last
      end

      # @return [Parsing::NodeObjects::Namespace, nil]
      def current_namespace
        analyzer.current_namespace
      end

      # @return [YARD::CodeObjects::Base, nil]
      def const_object
        return nil unless valid?
        namespace = current_namespace
        while namespace
          obj = registry.find(current_const_node.to_s(namespace.path))
          return obj if obj
          namespace = namespace.parent
        end
      end
    end
  end
end
