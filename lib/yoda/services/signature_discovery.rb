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

      # @return [Array<Store::Objects::MethodObject>]
      def method_candidates
        return [] unless valid?
        Store::Query::FindSignature.new(registry).select_on_multiple(receiver_objects, /\A#{Regexp.escape(index_word)}/)
      end

      private

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

      # @return [Array<Store::Objects::Base>]
      def receiver_objects
        return [] unless valid?
        @receiver_objects ||= nearest_send_node_info.receiver_candidates
      end

      # @return [Parsing::NodeObjects::SendNode, nil]
      def nearest_send_node
        @nearest_send_node ||= send_nodes_to_current_location.reverse.find { |node| node.on_parameter?(location) }
      end

      # @return [Typing::NodeInfo]
      def nearest_send_node_info
        evaluator.node_info(nearest_send_node.node)
      end

      # @return [SourceAnalyzer]
      def analyzer
        @analyzer ||= Parsing::SourceAnalyzer.from_source(source, location)
      end

      # @return [Evaluator]
      def evaluator
        @evaluator ||= Evaluator.new(ast: analyzer.ast, registry: registry)
      end
    end
  end
end
