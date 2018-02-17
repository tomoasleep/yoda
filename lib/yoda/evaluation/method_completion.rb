module Yoda
  module Evaluation
    class MethodCompletion
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

      # @return [true, false]
      def valid?
        !!(current_method && current_send)
      end

      # @return [Array<Store::Objects::Method>]
      def method_candidates
        return [] unless valid?
        receiver_values
          .map { |value| Store::Query::FindMethod.new(registry).select(value, /\A#{Regexp.escape(index_word)}/, visibility: method_visibility_of_send_node(current_send)) }
          .flatten
      end

      # @return [Range, nil]
      def substitution_range
        return nil unless valid?
        return current_send.selector_range if current_send.on_selector?(location)
        return Parsing::Range.new(current_send.next_location_to_dot, current_send.next_location_to_dot) if current_send.on_dot?(location)
        nil
      end

      private

      # @return [Array<Store::Objects::Base>]
      def receiver_values
        @receiver_values ||= begin
          if current_receiver_node
            calculate_values(current_receiver_node, registry, current_method)
          else
            [find_context_object(registry, current_method)].compact
          end
        end
      end

      # @return [Parsing::NodeObjects::MethodDefition, nil]
      def current_method
        analyzer.current_method
      end

      # @return [Parsing::NodeObjects::SendNode, nil]
      def current_send
        @current_send ||= begin
          node = analyzer.nodes_to_current_location_from_root.last
          return nil unless node.type == :send
          Parsing::NodeObjects::SendNode.new(node)
        end
      end

      # @return [SourceAnalyzer]
      def analyzer
        @analyzer ||= Parsing::SourceAnalyzer.from_source(source, location)
      end

      # @return [Parser::AST::Node, nil]
      def current_receiver_node
        current_send&.receiver_node
      end

      # @return [String, nil]
      def index_word
        return nil unless valid?
        @index_word ||= current_send.on_selector?(location) ? current_send.selector_name.slice(0..current_send.offset_in_selector(location)) : ''
      end
    end
  end
end
