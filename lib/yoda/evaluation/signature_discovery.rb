module Yoda
  module Evaluation
    class SignatureDiscovery
      include NodeEvaluatable
      attr_reader :registry, :source, :location

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
        @send_nodes_to_current_location ||= analyzer.nodes_to_current_location_from_root.map { |node| node.type == :send ? Parsing::NodeObjects::SendNode.new(node) : nil }.compact
      end

      # @return [String, nil]
      def index_word
        nearest_send_node&.selector_name
      end

      # @return [Store::Types::Base]
      def receiver_type
        @receiver_type ||=
        if nearest_send_node
          analyzer.calculate_type(nearest_send_node.receiver_node)
        else
          Store::Types::InstanceType.new(analyzer.namespace_object.path)
        end
      end

      # @return [Array<Store::Function>]
      def method_candidates
        return [] unless valid?
        receiver_values.map(&:methods).flatten.select { |meth| meth.name.to_s.start_with?(index_word) }
      end

      private

      # @return [Array<Store::Values::Base>]
      def receiver_values
        return [] unless valid?
        @receiver_values ||= self.calculate_values(nearest_send_node.receiver_node, registry, current_method)
      end

      # @return [Parsing::NodeObjects::MethodDefition, nil]
      def current_method
        analyzer.current_method
      end

      # @return [SourceAnalyzer]
      def analyzer
        @analyzer ||= Parsing::SourceAnalyzer.from_source(source, location)
      end
    end
  end
end
