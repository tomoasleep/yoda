module Yoda
  module Services
    # SignatureDiscovery infers method candidates for the nearest send node and specify the number of index of these parameters.
    # SignatureDiscovery shows help for the current parameter of method candidates.
    class SignatureDiscovery
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

      def valid?
        !!nearest_send_node
      end

      # @return [Parsing::NodeObjects::SendNode, nil]
      def nearest_send_node
        @nearest_send_node ||= send_nodes_to_current_location.reverse.find { |node| node.on_parameter?(location) }
      end

      # @return [Array<Parsing::NodeObjects::SendNode>]
      def send_nodes_to_current_location
        @send_nodes_to_current_location ||= begin
          analyzer.nodes_to_current_location_from_root.map do |node|
            node.type == :send ? Parsing::NodeObjects::SendNode.new(node) : nil
          end.compact
        end
      end

      # @return [String, nil]
      def index_word
        nearest_send_node&.selector_name
      end

      # @return [Model::TypeExpressions::Base]
      def receiver_type
        @receiver_type ||= begin
          if nearest_send_node
            evaluator.calculate_type(nearest_send_node.receiver_node)
          else
            Model::TypeExpressions::InstanceType.new(analyzer.namespace_object.path)
          end
        end
      end

      # @return [Array<Store::Objects::MethodObject>]
      def method_candidates
        return [] unless valid?
        receiver_values
          .map { |value| Store::Query::FindSignature.new(registry).select(value, /\A#{Regexp.escape(index_word)}/) }
          .flatten
      end

      private

      # @return [Array<Store::Values::Base>]
      def receiver_values
        return [] unless valid?
        @receiver_values ||= evaluator.calculate_values(nearest_send_node.receiver_node)
      end

      # @return [SourceAnalyzer]
      def analyzer
        @analyzer ||= Parsing::SourceAnalyzer.from_source(source, location)
      end

      # @return [Evaluator]
      def evaluator
        @evaluator ||= Evaluator.from_ast(registry, analyzer.ast, location)
      end
    end
  end
end
