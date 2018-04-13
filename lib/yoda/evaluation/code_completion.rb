module Yoda
  module Evaluation
    class CodeCompletion
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
        !!(current_send)
      end

      # @return [Array<Store::Objects::Method>]
      def method_candidates
        return [] unless valid?
        receiver_values
          .map { |value| Store::Query::FindSignature.new(registry).select(value, /\A#{Regexp.escape(index_word)}/, visibility: method_visibility_of_send_node(current_send)) }
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

      # @param send_node [Parsing::NodeObjects::SendNode]
      # @return [Array<Symbol>]
      def method_visibility_of_send_node(send_node)
        if send_node.receiver_node
          %i(public)
        else
          %i(public private protected)
        end
      end

      # @return [Array<Store::Objects::Base>]
      def receiver_values
        @receiver_values ||= begin
          if current_receiver_node
            evaluator.calculate_values(current_receiver_node)
          else
            # implicit call for self
            [evaluator.scope_constant]
          end
        end
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

      # @return [Evaluator]
      def evaluator
        @evaluator ||= Evaluator.from_ast(registry, analyzer.ast, location)
      end
    end
  end
end
