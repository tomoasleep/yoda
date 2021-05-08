module Yoda
  module Services
    # SignatureDiscovery infers method candidates for the nearest send node and specify the number of index of these parameters.
    # SignatureDiscovery shows help for the current parameter of method candidates.
    class SignatureDiscovery
      # @return [Evaluator]
      attr_reader :evaluator

      # @return [Parsing::Location]
      attr_reader :location

      # @param environment [Model::Environment]
      # @param registry [Store::Registry]
      # @param source   [String]
      # @param location [Parsing::Location]
      # @return [SignatureDiscovery]
      def self.from_source(environment:, source:, location:)
        new(
          evaluator: Evaluator.new(environment: environment, ast: Parsing.parse(source)),
          location: location
        )
      end

      # @param evaluator [Evaluator]
      # @param location [Parsing::Location]
      def initialize(evaluator:, location:)
        @evaluator = evaluator
        @location = location
      end

      def valid?
        !!nearest_send_node
      end

      # @return [Array<Model::FunctionSignatures::Warpper>]
      def method_candidates
        return [] unless valid?
        nearest_send_node_info.method_candidates
      end

      # @return [Integer, nil]
      def argument_number
        nearest_send_node&.expanded_arguments&.find_index { |node| node == nearest_argument_node }
      end

      private

      # @return [String, nil]
      def index_word
        nearest_send_node&.selector_name
      end

      # @return [AST::SendNode, nil]
      def nearest_send_node
        @nearest_send_node ||= current_node.query_ancestors(type: :send).reverse_each.find { |node| node.on_arguments?(location) }
      end

      # @return [Typing::NodeInfo]
      def nearest_send_node_info
        evaluator.node_info(nearest_send_node)
      end

      # @return [AST::ParameterNode, nil]
      def nearest_argument_node
        @nearest_argument_node ||= nearest_send_node&.expanded_arguments&.find { |node| node.positionally_include?(location) }
      end

      # @return [Parser::AST::Node]
      def current_node
        @current_node ||= evaluator.ast.positionally_nearest_child(location)
      end
    end
  end
end
